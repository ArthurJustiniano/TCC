import 'package:flutter/material.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carteirinha Digital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DigitalCardScreen(),
    );
  }
}

class DigitalCardScreen extends StatefulWidget {
  const DigitalCardScreen({super.key});

  @override
  State<DigitalCardScreen> createState() => carteirinha_page();
}

class carteirinha_page extends State<DigitalCardScreen> {
  // Estado de pagamentos: true = PAGO, false = não pago (PENDENTE/INADIMPLENTE)
  List<bool> paymentStatus = List<bool>.filled(12, false);
  bool _loading = true;
  String? _error;
  late final int _year;
  RealtimeChannel? _pgChannel;
  static const List<String> monthsPt = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    // Carrega pagamentos após a construção inicial para garantir que o Provider esteja pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDataAndSubscribe();
    });
  }

  Future<void> _initDataAndSubscribe() async {
    final userIdStr = Provider.of<UserData>(context, listen: false).userId;
    final userId = int.tryParse(userIdStr ?? '');
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Usuário inválido';
      });
      return;
    }
    await _loadYearPayments(userId);
    _subscribeToPaymentChanges(userId);
  }

  Future<void> _loadYearPayments(int userId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final from = DateTime(_year, 1, 1);
      final to = DateTime(_year, 12, 31);
      final rows = await Supabase.instance.client
          .from('pagamento')
          .select('data_pagamento, status')
          .eq('cod_passageiro', userId)
          .gte('data_pagamento', DateFormat('yyyy-MM-dd').format(from))
          .lte('data_pagamento', DateFormat('yyyy-MM-dd').format(to));

      final List<bool> months = List<bool>.filled(12, false);
      for (final row in rows) {
        final dateVal = row['data_pagamento'];
        DateTime? date;
        if (dateVal is String) {
          date = DateTime.tryParse(dateVal);
        } else if (dateVal is DateTime) {
          date = dateVal;
        }
        if (date == null) continue;
        final idx = date.month - 1;
        if (idx < 0 || idx > 11) continue;
        final statusStr = (row['status'] as String?)?.toUpperCase();
        months[idx] = statusStr == 'PAGO';
      }

      setState(() {
        paymentStatus = months;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar pagamentos: $e';
        _loading = false;
      });
    }
  }

  void _subscribeToPaymentChanges(int userId) {
    // Remove canal anterior se existir
    if (_pgChannel != null) {
      Supabase.instance.client.removeChannel(_pgChannel!);
      _pgChannel = null;
    }
    final ch = Supabase.instance.client.channel('pagamento_changes_user_$userId');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pagamento',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'cod_passageiro',
        value: userId,
      ),
      callback: (payload) async {
        // Recarrega sempre que houver mudança nos pagamentos deste usuário
        await _loadYearPayments(userId);
      },
    );
    ch.subscribe();
    _pgChannel = ch;
  }

  @override
  void dispose() {
    if (_pgChannel != null) {
      Supabase.instance.client.removeChannel(_pgChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bloqueio de acesso: somente passageiros (tipo 1) podem ver esta tela
    final userType = Provider.of<UserProfileData>(context).userType;
    if (userType == 2 || userType == 3) {
      // Mostra aviso e retorna uma tela vazia com botão de voltar
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carteirinha Digital'),
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock, size: 48, color: Colors.redAccent),
                SizedBox(height: 12),
                Text(
                  'Acesso restrito. Apenas passageiros podem visualizar a carteirinha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteirinha Digital'),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView( // Added SingleChildScrollView
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
                color: Colors.blue[400],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Provider.of<UserData>(context).userName ?? Provider.of<UserProfileData>(context).name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${Provider.of<UserData>(context).userId ?? '-'}',
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                          const Icon(Icons.directions_bus, size: 40, color: Colors.indigo),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Status de Pagamento Mensal:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final String month = monthsPt[index];
                          return MonthPaymentStatus(
                            month: month,
                            isPaid: paymentStatus[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MonthPaymentStatus extends StatelessWidget {
  const MonthPaymentStatus({super.key, required this.month, required this.isPaid});

  final String month;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPaid ? Colors.green[400] : Colors.red[400],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Icon(
              isPaid ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
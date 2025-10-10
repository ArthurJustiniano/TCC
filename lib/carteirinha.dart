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
          title: const Text(
            'Carteirinha Digital',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: const Color(0xFF1565C0),
          elevation: 0,
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F7FA),
                Color(0xFFE8EDF4),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Acesso Restrito',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apenas passageiros podem visualizar a carteirinha digital.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carteirinha Digital',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F7FA),
                Color(0xFFE8EDF4),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 0,
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF1976D2),
                          Color(0xFF1565C0),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_loading)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: const LinearProgressIndicator(
                                minHeight: 6,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Header com informações do usuário
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
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
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'ID: ${Provider.of<UserData>(context).userId ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.directions_bus, size: 28, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Título da seção de pagamentos
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.payment, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: const Text(
                                  'Status de Pagamento Mensal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ano $_year',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                // Primeira linha (Jan-Abr)
                                Row(
                                  children: [
                                    for (int i = 0; i < 4; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 3 ? 8 : 0,
                                          ),
                                          child: MonthPaymentStatus(
                                            month: monthsPt[i],
                                            isPaid: paymentStatus[i],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Segunda linha (Mai-Ago)
                                Row(
                                  children: [
                                    for (int i = 4; i < 8; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 7 ? 8 : 0,
                                          ),
                                          child: MonthPaymentStatus(
                                            month: monthsPt[i],
                                            isPaid: paymentStatus[i],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Terceira linha (Set-Dez)
                                Row(
                                  children: [
                                    for (int i = 8; i < 12; i++)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 11 ? 8 : 0,
                                          ),
                                          child: MonthPaymentStatus(
                                            month: monthsPt[i],
                                            isPaid: paymentStatus[i],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Legenda
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.green[400],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Pago',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Pendente',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80, // Altura fixa para consistência
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPaid 
            ? [
                const Color(0xFF4CAF50),
                const Color(0xFF388E3C),
              ]
            : [
                const Color(0xFFF44336),
                const Color(0xFFD32F2F),
              ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isPaid ? Colors.green : Colors.red).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Feedback tátil ao tocar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$month: ${isPaid ? "Pagamento realizado" : "Pagamento pendente"}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: isPaid ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
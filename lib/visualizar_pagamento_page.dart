import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider<PaymentData>(
      create: (context) => PaymentData(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class PaymentData extends ChangeNotifier {
  final List<AppUser> _users = [];
  bool _isLoading = false;
  String? _error;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsersFromDatabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Iniciando busca de usuários...');
      
      final response = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nome_usuario, pagamento_status, tipo_usuario')
          .eq('tipo_usuario', 1)  // Filtrar apenas passageiros (tipo 1)
          .order('id_usuario');  // Ordenar por ID para ter uma ordem consistente
          
      debugPrint('Query executada com sucesso');

      debugPrint('Resposta do Supabase: $response');
      debugPrint('Tipo da resposta: ${response.runtimeType}');

      _users.clear();
      for (var user in response) {
        _users.add(
          AppUser(
            name: user['nome_usuario'] ?? 'Desconhecido',
            id: user['id_usuario']?.toString() ?? '',
            paymentStatus: _mapPaymentStatus(user['pagamento_status'] ?? 'unknown'),
            tipoUsuario: (user['tipo_usuario'] as int?) ?? 0,
            appMetadata: user.containsKey('app_metadata') ? user['app_metadata'] : {},
            userMetadata: user.containsKey('user_metadata') ? user['user_metadata'] : {},
            aud: user['aud'] ?? '',
            createdAt: user['created_at'] != null ? DateTime.tryParse(user['created_at']) : null,
          ),
        );
      }
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Erro ao buscar usuários: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  PaymentStatus _mapPaymentStatus(String? status) {
    if (status == null) return PaymentStatus.pending;
    
    switch (status.toUpperCase()) {
      case 'PAGO':
        return PaymentStatus.paid;
      case 'PENDENTE':
        return PaymentStatus.pending;
      case 'INADIMPLENTE':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayString {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.failed:
        return 'Falhou';
    }
  }
}

class AppUser {
  final String name;
  final String id;
  final PaymentStatus paymentStatus;
  final int tipoUsuario;
  final Map<String, dynamic>? appMetadata;
  final Map<String, dynamic>? userMetadata;
  final String? aud;
  final DateTime? createdAt;

  AppUser({
    required this.name,
    required this.id,
    required this.paymentStatus,
    required this.tipoUsuario,
    this.appMetadata,
    this.userMetadata,
    this.aud,
    this.createdAt,
  });

  AppUser copyWith({
    String? name,
    String? id,
    PaymentStatus? paymentStatus,
    int? tipoUsuario,
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
    String? aud,
    DateTime? createdAt,
  }) {
    return AppUser(
      name: name ?? this.name,
      id: id ?? this.id,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      appMetadata: appMetadata ?? this.appMetadata,
      userMetadata: userMetadata ?? this.userMetadata,
      aud: aud ?? this.aud,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asseumir Payment Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    // Buscar os usuários quando a tela é carregada
    Future.microtask(() {
      context.read<PaymentData>().fetchUsersFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            const Icon(Icons.directions_bus, color: Colors.indigo, size: 40),
            const SizedBox(width: 8),
            const Text('Asseumir', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Consumer<PaymentData>(
        builder: (context, paymentData, child) {
          if (paymentData.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar usuários:'),
                  Text(paymentData.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => paymentData.fetchUsersFromDatabase(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          
          if (paymentData.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando usuários...'),
                ],
              ),
            );
          }

          if (paymentData.users.isEmpty) {
            return const Center(
              child: Text('Nenhum usuário encontrado'),
            );
          }

          return ListView.builder(
            itemCount: paymentData.users.length,
            itemBuilder: (context, index) {
              final user = paymentData.users[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person), // Ícone de pessoa
                          const SizedBox(width: 8),
                          Text(user.name),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentDetailsScreen(userId: user.id),
                            ),
                          );
                        },
                        child: const Text('Verificar Pagamento'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentDetailsScreen extends StatefulWidget {
  final String userId;

  const PaymentDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  late final int _passengerId;
  final int _year = DateTime.now().year;
  bool _loading = true;
  String? _error;

  // One status per month (0..11). Defaults to pending.
  late List<PaymentStatus> _monthStatuses;
  // Track existing row IDs per month to know when to update vs insert.
  late List<int?> _monthRowIds;

  @override
  void initState() {
    super.initState();
    _passengerId = int.tryParse(widget.userId) ?? 0;
    _monthStatuses = List.filled(12, PaymentStatus.pending);
    _monthRowIds = List.filled(12, null);
    _loadYearPayments();
  }

  Future<void> _loadYearPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final from = DateTime(_year, 1, 1);
      final to = DateTime(_year, 12, 31);
      final rows = await Supabase.instance.client
          .from('pagamento')
          .select('id_pagamento, data_pagamento, status')
          .eq('cod_passageiro', _passengerId)
          .gte('data_pagamento', DateFormat('yyyy-MM-dd').format(from))
          .lte('data_pagamento', DateFormat('yyyy-MM-dd').format(to));

      for (final row in rows) {
        final dateVal = row['data_pagamento'];
        DateTime? date;
        if (dateVal is String) {
          date = DateTime.tryParse(dateVal);
        } else if (dateVal is DateTime) {
          date = dateVal;
        }
        if (date == null) continue;
        final mIndex = date.month - 1; // 0..11
        if (mIndex < 0 || mIndex > 11) continue;
        _monthRowIds[mIndex] = (row['id_pagamento'] as num).toInt();
        final status = (row['status'] as String?)?.toUpperCase();
        switch (status) {
          case 'PAGO':
            _monthStatuses[mIndex] = PaymentStatus.paid;
            break;
          case 'INADIMPLENTE':
            _monthStatuses[mIndex] = PaymentStatus.failed;
            break;
          default:
            _monthStatuses[mIndex] = PaymentStatus.pending;
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar pagamentos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveMonth(int monthIndex, PaymentStatus status) async {
    final month = monthIndex + 1; // 1..12
    final monthDate = DateTime(_year, month, 1);

    // Map status back to DB string
    String dbStatus;
    switch (status) {
      case PaymentStatus.paid:
        dbStatus = 'PAGO';
        break;
      case PaymentStatus.failed:
        dbStatus = 'INADIMPLENTE';
        break;
      case PaymentStatus.pending:
        dbStatus = 'PENDENTE';
        break;
    }

    try {
      final rowId = _monthRowIds[monthIndex];
      if (rowId != null) {
        // Update existing row for this month
        await Supabase.instance.client
            .from('pagamento')
            .update({
              'status': dbStatus,
              // Gravamos o 1º dia do mês como referência do mês.
              'data_pagamento': DateFormat('yyyy-MM-dd').format(monthDate),
            })
            .eq('id_pagamento', rowId);
      } else {
        // Insert new row for this month
        final inserted = await Supabase.instance.client
            .from('pagamento')
            .insert({
              'cod_passageiro': _passengerId,
              'status': dbStatus,
              'data_pagamento': DateFormat('yyyy-MM-dd').format(monthDate),
              // 'valor': null, // opcional
            })
            .select('id_pagamento')
            .single();
        _monthRowIds[monthIndex] = (inserted['id_pagamento'] as num).toInt();
      }

      setState(() {
        _monthStatuses[monthIndex] = status;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento atualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.read<PaymentData>().users.firstWhere((u) => u.id == widget.userId);
    final userType = context.read<UserProfileData>().userType; // 2 = motorista, 3 = admin
    final canEdit = userType == 2 || userType == 3;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Detalhes do Pagamento', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadYearPayments,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Passageiro: ${appUser.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('ID do Usuário: ${appUser.id}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pagamentos do Ano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('$_year'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3.2,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            const monthsPt = [
                              'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                              'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
                            ];
                            final monthName = monthsPt[index];
                            final status = _monthStatuses[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      monthName[0].toUpperCase() + monthName.substring(1),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: canEdit
                                        ? DropdownButton<PaymentStatus>(
                                            value: status,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(value: PaymentStatus.paid, child: Text('Pago')),
                                              DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pendente')),
                                              DropdownMenuItem(value: PaymentStatus.failed, child: Text('Inadimplente')),
                                            ],
                                            onChanged: (val) {
                                              if (val == null) return;
                                              _saveMonth(index, val);
                                            },
                                          )
                                        : Text(status.displayString),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (!canEdit)
                        const Text(
                          'Apenas administradores e motoristas podem editar.',
                          style: TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class VisualizarPagamentoPage extends StatelessWidget {
  const VisualizarPagamentoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualizar Pagamentos'),
        backgroundColor: Colors.blue,
      ),
      body: const UserListScreen(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:intl/intl.dart';

// Removido o main() para evitar conflitos

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
          .select('id_usuario, nome_usuario, tipo_usuario')
          .eq('tipo_usuario', 1)  // Filtrar apenas passageiros (tipo 1)
          .order('id_usuario');  // Ordenar por ID para ter uma ordem consistente
          
      debugPrint('Query executada com sucesso');
      debugPrint('Resposta do Supabase: $response');

      _users.clear();
      
      // Para cada usuário, calcular o status baseado nos pagamentos
      for (var user in response) {
        final userId = user['id_usuario'];
        final paymentStatus = await _calculateUserPaymentStatus(userId);
        
        _users.add(
          AppUser(
            name: user['nome_usuario'] ?? 'Desconhecido',
            id: userId?.toString() ?? '',
            paymentStatus: paymentStatus,
            tipoUsuario: (user['tipo_usuario'] as int?) ?? 0,
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

  // Novo método para calcular o status baseado nos pagamentos atuais
  Future<PaymentStatus> _calculateUserPaymentStatus(int userId) async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;
      
      // Buscar pagamentos do ano atual
      final from = DateTime(currentYear, 1, 1);
      final to = DateTime(currentYear, 12, 31);
      
      final payments = await Supabase.instance.client
          .from('pagamento')
          .select('data_pagamento, status')
          .eq('cod_passageiro', userId)
          .gte('data_pagamento', DateFormat('yyyy-MM-dd').format(from))
          .lte('data_pagamento', DateFormat('yyyy-MM-dd').format(to));

      // Verificar pagamentos até o mês atual
      bool hasUnpaidMonths = false;
      List<int> paidMonths = [];
      
      // Mapear os meses pagos
      for (final payment in payments) {
        final dateVal = payment['data_pagamento'];
        DateTime? date;
        if (dateVal is String) {
          date = DateTime.tryParse(dateVal);
        } else if (dateVal is DateTime) {
          date = dateVal;
        }
        
        if (date != null && payment['status'] == 'PAGO') {
          paidMonths.add(date.month);
        }
      }
      
      // Verificar se todos os meses até o atual estão pagos
      for (int month = 1; month <= currentMonth; month++) {
        if (!paidMonths.contains(month)) {
          hasUnpaidMonths = true;
          break;
        }
      }
      
      return hasUnpaidMonths ? PaymentStatus.pending : PaymentStatus.paid;
    } catch (e) {
      debugPrint('Erro ao calcular status do usuário $userId: $e');
      return PaymentStatus.pending; // Default para pendente em caso de erro
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayString {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
    }
  }
}

class AppUser {
  final String name;
  final String id;
  final PaymentStatus paymentStatus;
  final int tipoUsuario;

  AppUser({
    required this.name,
    required this.id,
    required this.paymentStatus,
    required this.tipoUsuario,
  });

  AppUser copyWith({
    String? name,
    String? id,
    PaymentStatus? paymentStatus,
    int? tipoUsuario,
  }) {
    return AppUser(
      name: name ?? this.name,
      id: id ?? this.id,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
    );
  }
}

// Classe principal que será usada pelas outras páginas
class VisualizarPagamentoPage extends StatelessWidget {
  const VisualizarPagamentoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentData>(
      create: (context) => PaymentData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Visualizar Pagamentos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F7FA),
                Color(0xFFE8EEF2),
              ],
            ),
          ),
          child: const UserListScreen(),
        ),
      ),
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
      body: Consumer<PaymentData>(
        builder: (context, paymentData, child) {
          if (paymentData.error != null) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Erro ao Carregar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paymentData.error!,
                        style: const TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => paymentData.fetchUsersFromDatabase(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          if (paymentData.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Carregando usuários...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF546E7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (paymentData.users.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum Usuário Encontrado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Não há passageiros cadastrados no sistema.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7F8C8D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667eea),
                            Color(0xFF764ba2),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passageiros Cadastrados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${paymentData.users.length} usuário(s) encontrado(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: paymentData.users.length,
                      itemBuilder: (context, index) {
                        final user = paymentData.users[index];
                        Color statusColor;
                        String statusText;
                        IconData statusIcon;
                        
                        switch (user.paymentStatus) {
                          case PaymentStatus.paid:
                            statusColor = const Color(0xFF4CAF50);
                            statusText = 'Em Dia';
                            statusIcon = Icons.check_circle;
                            break;
                          case PaymentStatus.pending:
                            statusColor = const Color(0xFFFF9800);
                            statusText = 'Pendente';
                            statusIcon = Icons.schedule;
                            break;
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangeNotifierProvider.value(
                                    value: paymentData,
                                    child: PaymentDetailsScreen(userId: user.id),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF1976D2),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              statusIcon,
                                              size: 16,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Ver Detalhes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
          case 'PENDENTE':
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
    // Buscar o usuário de forma mais segura
    final paymentData = context.read<PaymentData>();
    AppUser? appUser;
    
    try {
      appUser = paymentData.users.firstWhere((u) => u.id == widget.userId);
    } catch (e) {
      appUser = AppUser(
        id: widget.userId,
        name: 'Usuário ID: ${widget.userId}',
        paymentStatus: PaymentStatus.pending,
        tipoUsuario: 1,
      );
    }
    
    final userType = context.read<UserProfileData>().userType; // 2 = motorista, 3 = admin
    final canEdit = userType == 2 || userType == 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Pagamento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando detalhes...',
                      style: TextStyle(
                        color: Color(0xFF546E7A),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Erro ao Carregar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadYearPayments,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          appUser.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${appUser.id}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pagamentos do Ano',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_year',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                    
                                    Color statusColor;
                                    switch (status) {
                                      case PaymentStatus.paid:
                                        statusColor = const Color(0xFF4CAF50);
                                        break;
                                      case PaymentStatus.pending:
                                        statusColor = const Color(0xFFFF9800);
                                        break;
                                    }
                                    
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              monthName.substring(0, 3),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: statusColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 3,
                                            child: canEdit
                                                ? DropdownButton<PaymentStatus>(
                                                    value: status,
                                                    isExpanded: true,
                                                    underline: Container(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    items: const [
                                                      DropdownMenuItem(value: PaymentStatus.paid, child: Text('Pago')),
                                                      DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pendente')),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val == null) return;
                                                      _saveMonth(index, val);
                                                    },
                                                  )
                                                : Text(
                                                    status.displayString,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (!canEdit)
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFFFF3CD),
                                  border: Border.all(
                                    color: const Color(0xFFFFE082),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Apenas administradores e motoristas podem editar os status de pagamento.',
                                        style: TextStyle(
                                          color: Color(0xFF6B4E00),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
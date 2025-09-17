import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class PaymentDetailsScreen extends StatelessWidget {
  final String userId;

  const PaymentDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<PaymentData>(context, listen: false)
        .users
        .firstWhere((user) => user.id == userId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Detalhes do Pagamento', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status do Pagamento:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              user.paymentStatus.displayString,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text('ID do Usuário: ${user.id}'),
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
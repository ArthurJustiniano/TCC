import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider<PaymentData>(
      create: (context) => PaymentData(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class PaymentData extends ChangeNotifier {
  final List<User> _users = [
    User(name: 'Alice', id: '1', paymentStatus: PaymentStatus.pending),
    User(name: 'Bob', id: '2', paymentStatus: PaymentStatus.paid),
    User(name: 'Charlie', id: '3', paymentStatus: PaymentStatus.pending),
    User(name: 'David', id: '4', paymentStatus: PaymentStatus.paid),
  ];

  List<User> get users => _users;

  void updatePaymentStatus(String userId, PaymentStatus status) {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(paymentStatus: status);
      notifyListeners();
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
      default:
        return 'Desconhecido';
    }
  }
}

class User {
  final String name;
  final String id;
  final PaymentStatus paymentStatus;

  User({
    required this.name,
    required this.id,
    required this.paymentStatus,
  });

  User copyWith({
    String? name,
    String? id,
    PaymentStatus? paymentStatus,
  }) {
    return User(
      name: name ?? this.name,
      id: id ?? this.id,
      paymentStatus: paymentStatus ?? this.paymentStatus,
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

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

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
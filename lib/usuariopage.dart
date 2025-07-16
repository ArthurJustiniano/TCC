import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider<UserProfileData>(
      create: (context) => UserProfileData(),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class UserProfileData extends ChangeNotifier {
  UserProfileData()
      : name = 'João da Silva',
        email = 'joao.silva@exemplo.com',
        phone = '123-456-7890',
        monthlyPayments = {
          'Jan': false,
          'Fev': false,
          'Mar': false,
          'Abr': false,
          'Mai': false,
          'Jun': false,
          'Jul': false,
          'Ago': false,
          'Set': false,
          'Out': false,
          'Nov': false,
          'Dez': false,
        };

  String name;
  String email;
  String phone;
  Map<String, bool> monthlyPayments;

  void togglePayment(String month, bool? newValue) {
    if (newValue != null) {
      monthlyPayments[month] = newValue;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfil do Usuário',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const UserProfileScreen(),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileData = Provider.of<UserProfileData>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 90,
                height: 120,
                child: Image.network(
                  'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Informações do Perfil',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 16),
            _ProfileInfoTile(title: 'Nome', value: userProfileData.name),
            _ProfileInfoTile(title: 'Email', value: userProfileData.email),
            _ProfileInfoTile(title: 'Telefone', value: userProfileData.phone),
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 32, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  'Pagamentos Mensais',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: userProfileData.monthlyPayments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  String month = userProfileData.monthlyPayments.keys.elementAt(index);
                  return _MonthPaymentCard(month: month, isPaid: userProfileData.monthlyPayments[month]!);
                },
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userProfileData.monthlyPayments.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.blueGrey),
              itemBuilder: (context, index) {
                String month = userProfileData.monthlyPayments.keys.elementAt(index);
                return ListTile(
                  title: Text(month, style: const TextStyle(color: Colors.blueGrey)),
                  trailing: Checkbox(
                    activeColor: Colors.blue[400],
                    value: userProfileData.monthlyPayments[month]!,
                    onChanged: (bool? newValue) {
                      userProfileData.togglePayment(month, newValue);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
    );
  }
}

class _MonthPaymentCard extends StatelessWidget {
  const _MonthPaymentCard({
    required this.month,
    required this.isPaid,
  });

  final String month;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Checkbox(
              activeColor: Colors.blue[400],
              value: isPaid,
              onChanged: null,
            ),
          ],
        ),
      ),
    );
  }
}
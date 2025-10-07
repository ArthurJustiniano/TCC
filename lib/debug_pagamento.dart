import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/pagamento_page.dart';

class DebugPagamentoPage extends StatelessWidget {
  const DebugPagamentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Pagamento'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<UserProfileData>(
              builder: (context, userProfile, child) {
                return Column(
                  children: [
                    Text('UserType: ${userProfile.userType}'),
                    Text('Name: ${userProfile.name}'),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  debugPrint('Debug: Tentando navegar para PaymentPage');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentPage(),
                    ),
                  );
                } catch (e) {
                  debugPrint('Debug: Erro ao navegar: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              child: const Text('Ir para Pagamento'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                try {
                  debugPrint('Debug: Tentando navegar direto para PaymentMethodsScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                } catch (e) {
                  debugPrint('Debug: Erro ao navegar direto: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              child: const Text('Ir direto para PaymentMethodsScreen'),
            ),
          ],
        ),
      ),
    );
  }
}
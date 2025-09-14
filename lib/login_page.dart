import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tela de Login'),
            ElevatedButton(
              onPressed: () {
                // Implementar lógica de login aqui
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
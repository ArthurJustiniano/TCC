import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  String _tipoLabel(int t) {
    switch (t) {
      case 1:
        return 'Passageiro';
      case 2:
        return 'Motorista';
      case 3:
        return 'Admin';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileData = Provider.of<UserProfileData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Copiar email',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: userProfileData.email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copiado.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue[200],
                child: Text(
                  userProfileData.name.isNotEmpty ? userProfileData.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(_tipoLabel(userProfileData.userType)),
                  avatar: const Icon(Icons.verified_user, size: 18, color: Colors.white),
                  backgroundColor: Colors.blue[600],
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Informações do Perfil',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 16),
            _ProfileInfoTile(title: 'Nome', value: userProfileData.name),
            _ProfileInfoTile(title: 'Email', value: userProfileData.email),
            _ProfileInfoTile(title: 'Telefone', value: userProfileData.phone),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: userProfileData.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Telefone copiado.')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Telefone'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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


import 'package:app_flutter/usuariopage.dart' as usuariopage;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Maispage extends StatelessWidget {
  const Maispage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mais'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil do Usuário'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const usuariopage.UserProfileScreen()),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Sobre'),
            onTap: null, // Implementar ação
          ),
          const ListTile(
            leading: Icon(Icons.help),
            title: Text('Ajuda'),
            onTap: null, // Implementar ação
          ),
        ],
      ),
    );
  }
}

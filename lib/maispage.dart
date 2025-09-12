import 'package:app_flutter/usuariopage.dart' as usuariopage;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/map.page.dart';

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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.drive_eta, color: Colors.blue),
            title: const Text('Modo Motorista (Iniciar Rota)'),
            subtitle: const Text('Envia sua localização para os passageiros'),
            onTap: () {
              // TODO: Obter o ID do motorista que fez login.
              // Por enquanto, usaremos 'James' como exemplo.
              const driverId = 'James';
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage(trackedUserId: driverId, isDriver: true)),
              );
            },
          ),
          const Divider(),
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

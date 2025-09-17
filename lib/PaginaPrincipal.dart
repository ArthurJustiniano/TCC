import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/localizacao.dart' as localizacao;
import 'package:app_flutter/carteirinha.dart' as carteirinha;
import 'package:app_flutter/chat/user_list_page.dart';
import 'package:app_flutter/mural.dart' as mural;
import 'package:app_flutter/usuariopage.dart' as usuariopage;
import 'package:app_flutter/crud/login.dart';
import 'package:app_flutter/visualizar_pagamento_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// TODO: A página de chat agora é para conversas 1-para-1 e precisa ser chamada
// a partir de uma lista de usuários/conversas, não como uma página principal.
class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainDrawer();
  }
}

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    localizacao.BusAppHomePage(),
    const carteirinha.DigitalCardScreen(),
    const ChatUserListPage(),
    const mural.NewsPage(),
    const usuariopage.UserProfileScreen(), // Adicionando a página de usuário
  ];

  final List<String> _titles = [
    'Ônibus',
    'Carteirinha',
    'Bate-papo',
    'Mural',
    'Usuário' // Adicionando o título da página de usuário
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Fecha o menu de navegação
  }

  @override
  Widget build(BuildContext context) {
    final userType = Provider.of<UserProfileData>(context).userType; // Obtém o tipo de usuário

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Bem-vindo, ${Provider.of<UserProfileData>(context).name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus),
              title: const Text('Ônibus'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Carteirinha'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Bate-papo'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Mural'),
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Usuário'),
              onTap: () => _onItemTapped(4),
            ),
            if (userType == 2 || userType == 3) // Verifica se é motorista ou administrador
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Visualizar Pagamentos'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VisualizarPagamentoPage(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Limpa as credenciais salvas

                // Redireciona para a tela de login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

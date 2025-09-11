import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/localizacao.dart' as localizacao;
import 'package:app_flutter/carteirinha.dart' as carteirinha;
import 'package:app_flutter/chatpage.dart' as chatpage;
import 'package:app_flutter/mural.dart' as mural;
import 'package:app_flutter/usuariopage.dart' as usuariopage;

String nomeUsuario = "DAVI";
String websocket = 'wss://seu-endereco-websocket';


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
    chatpage.ChatPage(
      username: nomeUsuario,
      wsUrl: websocket,
    ),
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
                'Bem-vindo, $nomeUsuario',
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
            ), // Adicionando a opção de usuário no menu
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

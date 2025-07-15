import 'package:flutter/material.dart';
import 'package:app_flutter/localizacao.dart' as localizacao;
import 'package:app_flutter/carteirinha.dart' as carteirinha;
import 'package:app_flutter/chatpage.dart' as chatpage;

String nomeUsuario = "DAVI";
String websocket = 'wss://seu-endereco-websocket';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RotaFácil',
      home: const MainTabs(),
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    localizacao.BusAppHomePage(),
    carteirinha.carteirinha_page(),
    chatpage.ChatPage(
      username: nomeUsuario,
      wsUrl: websocket,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Ônibus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Carteirinha',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Bate-papo',
          ),
        ],
      ),
    );
  }
}
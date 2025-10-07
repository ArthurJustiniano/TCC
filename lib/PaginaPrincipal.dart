import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/localizacao.dart' as localizacao;
import 'package:app_flutter/carteirinha.dart' as carteirinha;
import 'package:app_flutter/chat/user_list_page.dart';
import 'package:app_flutter/mural.dart' as mural;
import 'package:app_flutter/usuariopage.dart' as usuariopage;
import 'package:app_flutter/crud/login.dart';
import 'package:app_flutter/visualizar_pagamento_page.dart';
import 'package:app_flutter/cadastro_adm.dart';
import 'package:app_flutter/pagamento_page.dart';
import 'package:app_flutter/deletar_usuario.dart';
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
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = Provider.of<UserProfileData>(context).userType; // Obtém o tipo de usuário

    // Se for motorista (2) ou administrador (3) e a aba selecionada for a Carteirinha (índice 1),
    // redireciona automaticamente para a primeira aba para impedir o acesso.
    if ((userType == 2 || userType == 3) && _selectedIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            color: _selectedIndex == 0 ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2196F3),
                Color(0xFF1976D2),
                Color(0xFF1565C0),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF8F9FA),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2196F3),
                    Color(0xFF1976D2),
                    Color(0xFF1565C0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Bem-vindo!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Provider.of<UserProfileData>(context).name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.directions_bus,
                    title: 'Ônibus',
                    index: 0,
                    selectedIndex: _selectedIndex,
                    onTap: () => _onItemTapped(0),
                  ),
                  if (userType == 1)
                    _buildDrawerItem(
                      icon: Icons.credit_card,
                      title: 'Carteirinha',
                      index: 1,
                      selectedIndex: _selectedIndex,
                      onTap: () => _onItemTapped(1),
                    ),
                  if (userType == 1 || userType == 3)
                    _buildDrawerItem(
                      icon: Icons.attach_money,
                      title: 'Pagamentos',
                      onTap: () async {
                        try {
                          debugPrint('PaginaPrincipal: Tentando navegar para PaymentPage...');
                          final userProfileData = context.read<UserProfileData>();
                          debugPrint('PaginaPrincipal: UserType antes da navegação: ${userProfileData.userType}');
                          
                          // Fechar o drawer primeiro
                          Navigator.pop(context);
                          
                          // Aguardar um frame antes de navegar
                          await Future.delayed(const Duration(milliseconds: 100));
                          
                          if (context.mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  debugPrint('PaginaPrincipal: Construindo PaymentPage...');
                                  return const PaymentPage();
                                },
                              ),
                            );
                            debugPrint('PaginaPrincipal: Navegação para PaymentPage finalizada');
                          }
                        } catch (e) {
                          debugPrint('PaginaPrincipal: Erro ao tentar navegar: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao abrir pagamentos: $e')),
                            );
                          }
                        }
                      },
                    ),
                  _buildDrawerItem(
                    icon: Icons.chat,
                    title: 'Bate-papo',
                    index: 2,
                    selectedIndex: _selectedIndex,
                    onTap: () => _onItemTapped(2),
                  ),
                  _buildDrawerItem(
                    icon: Icons.announcement,
                    title: 'Mural',
                    index: 3,
                    selectedIndex: _selectedIndex,
                    onTap: () => _onItemTapped(3),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Usuário',
                    index: 4,
                    selectedIndex: _selectedIndex,
                    onTap: () => _onItemTapped(4),
                  ),
                  if (userType == 2 || userType == 3)
                    _buildDrawerItem(
                      icon: Icons.payment,
                      title: 'Visualizar Pagamentos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisualizarPagamentoPage(),
                          ),
                        );
                      },
                    ),
                  if (userType == 3)
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Cadastrar Motorista/Admin',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUserRegistrationPage(),
                          ),
                        );
                      },
                    ),
                  if (userType == 3)
                    _buildDrawerItem(
                      icon: Icons.delete_forever,
                      title: 'Excluir Usuários',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeleteUsersPage(),
                          ),
                        );
                      },
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Divider(
                      color: Colors.grey,
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
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
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EDF4),
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    int? index,
    int? selectedIndex,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final bool isSelected = index != null && selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? const Color(0xFF1565C0).withOpacity(0.1) : null,
        border: isSelected 
          ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.3))
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? const Color(0xFF1565C0) 
                      : (iconColor != null ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                      ? Colors.white 
                      : (iconColor ?? const Color(0xFF1565C0)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                        ? const Color(0xFF1565C0) 
                        : (textColor ?? const Color(0xFF2C3E50)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

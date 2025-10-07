import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/user_data.dart';
import 'package:app_flutter/chatpage.dart';

class ChatUserListPage extends StatefulWidget {
  const ChatUserListPage({super.key});

  @override
  State<ChatUserListPage> createState() => _ChatUserListPageState();
}

class _ChatUserListPageState extends State<ChatUserListPage> {
  bool _loading = true;
  String? _error;
  List<_ChatUser> _users = const [];
  int _myId = 0;
  int _targetTipo = 0; // 1 passageiro, 2 motorista; admin (3) vê todos

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final userData = Provider.of<UserData>(context, listen: false);
      final userProfile = Provider.of<UserProfileData>(context, listen: false);

      _myId = int.tryParse(userData.userId ?? '') ?? 0;
      final myTipo = userProfile.userType;

      // Passageiro (1) fala com motoristas (2); Motorista (2) fala com passageiros (1); Admin (3) vê todos
      if (myTipo == 1) {
        _targetTipo = 2;
      } else if (myTipo == 2) {
        _targetTipo = 1;
      } else {
        _targetTipo = 0; // admin
      }

      await _loadUsers();
    } catch (e) {
      setState(() {
        _error = 'Erro ao inicializar: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final query = Supabase.instance.client.from('usuario').select('id_usuario, nome_usuario, tipo_usuario');
      final data = _targetTipo == 0
          ? await query
          : await query.eq('tipo_usuario', _targetTipo);

      final list = (data as List)
          .map((m) => _ChatUser(
                id: (m['id_usuario'] is int) ? m['id_usuario'] as int : int.tryParse('${m['id_usuario']}') ?? 0,
                name: (m['nome_usuario'] ?? '').toString(),
                tipo: (m['tipo_usuario'] is int) ? m['tipo_usuario'] as int : int.tryParse('${m['tipo_usuario']}') ?? 0,
              ))
          .where((u) => u.id != _myId) // não listar a si mesmo
          .toList();

      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar usuários: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Conversas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              // Implementar busca se necessário
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () {
              // Menu de opções
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando contatos...',
                      style: TextStyle(
                        color: Color(0xFF546E7A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Erro ao Carregar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.2),
                                    spreadRadius: 8,
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Color(0xFF667eea),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Nenhum contato disponível',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Não há usuários disponíveis para conversar no momento',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7F8C8D),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: const Color(0xFF667eea),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final subtitle = switch (user.tipo) {
                              1 => 'Passageiro',
                              2 => 'Motorista',
                              3 => 'Administrador',
                              _ => 'Usuário',
                            };
                            
                            Color typeColor = switch (user.tipo) {
                              1 => const Color(0xFF4CAF50), // Verde para passageiro
                              2 => const Color(0xFF2196F3), // Azul para motorista
                              3 => const Color(0xFFFF9800), // Laranja para admin
                              _ => const Color(0xFF9E9E9E),
                            };
                            
                            IconData typeIcon = switch (user.tipo) {
                              1 => Icons.person,
                              2 => Icons.drive_eta,
                              3 => Icons.admin_panel_settings,
                              _ => Icons.help,
                            };

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          receiverId: user.id,
                                          receiverUsername: user.name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Avatar do usuário
                                        Stack(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    typeColor.withOpacity(0.8),
                                                    typeColor,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(28),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: typeColor.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  user.name.isNotEmpty 
                                                      ? user.name[0].toUpperCase() 
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Indicador de status (online)
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(width: 16),
                                        
                                        // Informações do usuário
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.name,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF2C3E50),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: typeColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          typeIcon,
                                                          size: 14,
                                                          color: typeColor,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          subtitle,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: typeColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 8,
                                                    color: const Color(0xFF4CAF50),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Online agora',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF4CAF50),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  const Text(
                                                    'Toque para conversar',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF7F8C8D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        // Seta para indicar navegação
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Color(0xFF667eea),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatUser {
  final int id;
  final String name;
  final int tipo;
  const _ChatUser({required this.id, required this.name, required this.tipo});
}

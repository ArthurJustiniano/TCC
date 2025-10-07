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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      final subtitle = switch (u.tipo) {
                        1 => 'Passageiro',
                        2 => 'Motorista',
                        3 => 'Admin',
                        _ => 'Usuário',
                      };
                      return ListTile(
                        leading: CircleAvatar(child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')),
                        title: Text(u.name),
                        subtitle: Text(subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                receiverId: u.id,
                                receiverUsername: u.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
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

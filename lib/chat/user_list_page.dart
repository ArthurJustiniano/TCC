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
  RealtimeChannel? _notificationChannel;

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

      final List<_ChatUser> userList = [];
      
      for (final userData in (data as List)) {
        final userId = (userData['id_usuario'] is int) ? userData['id_usuario'] as int : int.tryParse('${userData['id_usuario']}') ?? 0;
        final userName = (userData['nome_usuario'] ?? '').toString();
        final userTipo = (userData['tipo_usuario'] is int) ? userData['tipo_usuario'] as int : int.tryParse('${userData['tipo_usuario']}') ?? 0;
        
        if (userId == _myId) continue; // não listar a si mesmo
        
        // Buscar contagem de mensagens não lidas para este usuário
        final chatRoomId = _createChatRoomId(_myId, userId);
        final unreadCount = await _getUnreadMessageCount(chatRoomId, userId);
        final lastMessageData = await _getLastMessage(chatRoomId);
        
        userList.add(_ChatUser(
          id: userId,
          name: userName,
          tipo: userTipo,
          unreadCount: unreadCount,
          lastMessage: lastMessageData['message'],
          lastMessageTime: lastMessageData['timestamp'],
        ));
      }

      setState(() {
        _users = userList;
        _loading = false;
      });
      
      _setupNotificationListener();
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar usuários: $e';
        _loading = false;
      });
    }
  }

  String _createChatRoomId(int userId1, int userId2) {
    if (userId1 > userId2) {
      return 'chat_${userId2}_$userId1';
    } else {
      return 'chat_${userId1}_$userId2';
    }
  }

  Future<int> _getUnreadMessageCount(String chatRoomId, int senderId) async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('chat_room_id', chatRoomId)
          .eq('sender_id', senderId)
          .eq('is_read', false);
      
      return (response as List).length;
    } catch (e) {
      debugPrint('Erro ao buscar mensagens não lidas: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> _getLastMessage(String chatRoomId) async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('message, created_at')
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: false)
          .limit(1);
      
      if ((response as List).isNotEmpty) {
        final data = response.first;
        return {
          'message': data['message'],
          'timestamp': DateTime.tryParse(data['created_at'] ?? ''),
        };
      }
      return {'message': null, 'timestamp': null};
    } catch (e) {
      debugPrint('Erro ao buscar última mensagem: $e');
      return {'message': null, 'timestamp': null};
    }
  }

  void _setupNotificationListener() {
    _notificationChannel = Supabase.instance.client.channel('inbox_$_myId');
    _notificationChannel?.onBroadcast(event: 'chat_message', callback: (payload) {
      // Atualizar a lista quando receber nova mensagem
      _loadUsers();
    });
    _notificationChannel?.subscribe();
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${messageTime.day}/${messageTime.month}';
    }
  }

  Future<void> _markMessagesAsRead(int senderId) async {
    final chatRoomId = _createChatRoomId(_myId, senderId);
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_room_id', chatRoomId)
          .eq('sender_id', senderId)
          .eq('is_read', false);
      
      // Recarregar a lista para atualizar os contadores
      _loadUsers();
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conversas'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _init();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _users.isEmpty
          ? const Center(
              child: Text(
                'Nenhum usuário disponível para conversa',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getUserColor(user.tipo),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (user.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                user.unreadCount > 99 ? '99+' : '${user.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: user.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: user.lastMessage != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.lastMessage!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: user.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (user.lastMessageTime != null)
                                Text(
                                  _formatMessageTime(user.lastMessageTime!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            _getUserTypeLabel(user.tipo),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      // Marcar mensagens como lidas antes de abrir o chat
                      if (user.unreadCount > 0) {
                        await _markMessagesAsRead(user.id);
                      }
                      
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverId: user.id,
                              receiverUsername: user.name,
                            ),
                          ),
                        ).then((_) {
                          // Recarregar a lista quando voltar do chat
                          _loadUsers();
                        });
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getUserColor(int tipo) {
    switch (tipo) {
      case 1:
        return Colors.green; // passageiro
      case 2:
        return Colors.orange; // motorista
      case 3:
        return Colors.purple; // admin
      default:
        return Colors.grey;
    }
  }

  String _getUserTypeLabel(int tipo) {
    switch (tipo) {
      case 1:
        return 'Passageiro';
      case 2:
        return 'Motorista';
      case 3:
        return 'Administrador';
      default:
        return 'Usuário';
    }
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
  }
}

class _ChatUser {
  final int id;
  final String name;
  final int tipo;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  const _ChatUser({
    required this.id,
    required this.name,
    required this.tipo,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
  });
}
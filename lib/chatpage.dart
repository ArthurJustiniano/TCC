import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/user_data.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final int receiverId;
  final String receiverUsername;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverUsername,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final RealtimeChannel _channel;
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  late final int _myUserId;
  late final String _myUsername;
  late final String _chatRoomId;
  bool _isLoading = true;
  String? _loadingError;

  @override
  void initState() {
    super.initState();

    // Busca os dados do usuário logado a partir dos Providers.
  // UserData.userId is stored as String?; convert to int if possible
  final userIdStr = Provider.of<UserData>(context, listen: false).userId;
  _myUserId = int.tryParse(userIdStr ?? '') ?? 0;
    _myUsername = Provider.of<UserProfileData>(context, listen: false).name;

    // Verificação de segurança: Garante que o usuário está logado antes de prosseguir.
    // O valor '0' é baseado na inicialização `int id = 0;` na sua classe UserData.
    if (_myUserId == 0) {
      // Usa um post-frame callback para navegar com segurança após o build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado.')),
          );
        }
      });
      return; // Interrompe a inicialização do chat.
    }

    // Cria um ID de sala de chat único e consistente.
    _chatRoomId = _createChatRoomId(_myUserId, widget.receiverId);

    _channel = Supabase.instance.client.channel(_chatRoomId);

    _channel.onBroadcast(event: 'message', callback: (payload) {
      // Não adiciona a mensagem se for do próprio usuário (já foi adicionada localmente).
      final payloadSender = _coerceInt(payload['sender_id']);
      if (payloadSender != _myUserId) {
        final message = _ChatMessage.fromMap(payload);
        // Garante que o widget ainda está na árvore antes de chamar setState.
        if (mounted) {
          setState(() {
            _messages.insert(0, message);
          });
        }
      }
    });

    _channel.subscribe();

    _loadInitialMessages();
  }

  int _coerceInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _createChatRoomId(int userId1, int userId2) {
    // Ordena os IDs para garantir que o ID da sala seja sempre o mesmo.
    if (userId1 > userId2) {
      return 'chat_${userId2}_$userId1';
    } else {
      return 'chat_${userId1}_$userId2';
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('chat_room_id', _chatRoomId)
          .order('created_at', ascending: false);

      final messages = (data as List)
          .map((item) => _ChatMessage.fromMap(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _messages.addAll(messages);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar mensagens: $e');
      if (mounted) {
        setState(() {
          _loadingError = 'Não foi possível carregar as mensagens.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final messageText = _controller.text.trim();

    // Adiciona a mensagem localmente para uma UI responsiva (UI Otimista).
    final localMessage = _ChatMessage(
      senderId: _myUserId,
      username: _myUsername,
      message: messageText,
    );
    setState(() {
      _messages.insert(0, localMessage);
    });
    _controller.clear();

    // Payload para salvar no banco de dados.
    final dbPayload = {
      'sender_id': _myUserId,
      'receiver_id': widget.receiverId,
      'chat_room_id': _chatRoomId,
      'message': messageText,
      'sender_username': _myUsername,
    };

    try {
      // 1. Salva no banco de dados.
      await Supabase.instance.client.from('messages').insert(dbPayload);

      // 2. Payload para enviar via broadcast para o outro usuário.
      final broadcastPayload = {
        'sender_id': _myUserId,
        'message': messageText,
        'username': _myUsername, // Nome do remetente para exibição
      };

      await _channel.sendBroadcastMessage(
        event: 'message',
        payload: broadcastPayload,
      );

      // 3. Também envia um broadcast para o canal de inbox do destinatário para acionar notificação
      final inboxChannel = Supabase.instance.client.channel('inbox_${widget.receiverId}');
      await inboxChannel.subscribe();
      await inboxChannel.sendBroadcastMessage(
        event: 'chat_message',
        payload: {
          'sender_id': _myUserId,
          'sender_username': _myUsername,
          'message': messageText,
          'chat_room_id': _chatRoomId,
        },
      );
      // Clean up the ephemeral channel used only for broadcasting
      Supabase.instance.client.removeChannel(inboxChannel);
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      // Se o envio falhar, remove a mensagem da lista e notifica o usuário.
      if (mounted) {
        setState(() {
          _messages.remove(localMessage);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falha ao enviar a mensagem. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUsername),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadingError != null) {
      return Center(child: Text(_loadingError!));
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text('Seja o primeiro a enviar uma mensagem!'),
      );
    }

    return ListView.builder(
      reverse: true, // Mostra as mensagens mais recentes embaixo
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _myUserId;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[400] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    msg.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  msg.message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue[700],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final int senderId;
  final String username;
  final String message;

  _ChatMessage({
    required this.senderId,
    required this.username,
    required this.message,
  });

  factory _ChatMessage.fromMap(Map<String, dynamic> map) {
    return _ChatMessage(
      // Converte sender_id de int ou string para int de forma segura
      senderId: (() {
        final v = map['sender_id'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      })(),
      // Obtém o nome de usuário de qualquer uma das fontes (broadcast ou DB).
      username: map['username'] ?? map['sender_username'] ?? 'Desconhecido',
      message: map['message'] ?? '',
    );
  }
}
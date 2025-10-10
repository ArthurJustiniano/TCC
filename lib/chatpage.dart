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
          // Marcar a mensagem como lida já que o usuário está vendo o chat
          _markMessagesAsRead();
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
      
      // Marcar mensagens não lidas do outro usuário como lidas
      await _markMessagesAsRead();
      
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

  Future<void> _markMessagesAsRead() async {
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('chat_room_id', _chatRoomId)
          .eq('sender_id', widget.receiverId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como lidas: $e');
    }
  }

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inSeconds < 30) {
      return 'agora';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
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
      'is_read': false, // Nova mensagem começa como não lida
    };

    try {
      // 1. Salva no banco de dados.
      await Supabase.instance.client.from('messages').insert(dbPayload);

      // 2. Payload para enviar via broadcast para o outro usuário.
      final broadcastPayload = {
        'sender_id': _myUserId,
        'message': messageText,
        'username': _myUsername, // Nome do remetente para exibição
        'created_at': DateTime.now().toIso8601String(),
      };

      await _channel.sendBroadcastMessage(
        event: 'message',
        payload: broadcastPayload,
      );

      // 3. Também envia um broadcast para o canal de inbox do destinatário para acionar notificação
      final inboxChannel = Supabase.instance.client.channel('inbox_${widget.receiverId}');
      inboxChannel.subscribe();
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
      ),
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
      return Container(
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Carregando conversa...',
                style: TextStyle(
                  color: Color(0xFF546E7A),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingError != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFFFEBEE),
            ],
          ),
        ),
        child: Center(
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
                    _loadingError!,
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadInitialMessages,
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
        ),
      );
    }

    if (_messages.isEmpty) {
      return Container(
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
        child: Center(
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
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inicie a conversa!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seja o primeiro a enviar uma mensagem',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final isMe = msg.senderId == _myUserId;
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isMe 
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF667eea),
                                Color(0xFF764ba2),
                              ],
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isMe 
                              ? const Color(0xFF667eea).withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          Text(
                            msg.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          msg.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : const Color(0xFF2C3E50),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMessageTime(msg.createdAt),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMe) ...[
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 8, bottom: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Botão de enviar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _sendMessage,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final int senderId;
  final String username;
  final String message;
  final DateTime createdAt;

  _ChatMessage({
    required this.senderId,
    required this.username,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
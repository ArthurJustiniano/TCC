class ChatNotification {
  final int chatRoomId;
  final int senderId;
  final String senderName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  ChatNotification({
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  factory ChatNotification.fromMap(Map<String, dynamic> map) {
    return ChatNotification(
      chatRoomId: map['chat_room_id'] ?? 0,
      senderId: map['sender_id'] ?? 0,
      senderName: map['sender_name'] ?? '',
      lastMessage: map['last_message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      unreadCount: map['unread_count'] ?? 0,
    );
  }
}
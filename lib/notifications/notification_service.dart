import 'dart:io';

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles local notifications and Realtime subscriptions for news and chat inbox.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  RealtimeChannel? _newsChannel;
  RealtimeChannel? _inboxChannel;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _fln.initialize(initSettings);

    // On Android 13+ request the POST_NOTIFICATIONS permission.
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    // Android 13+ requires runtime POST_NOTIFICATIONS permission; if you need, handle elsewhere.

    _initialized = true;
  }

  /// Subscribe a broadcast for news board. Any device listening gets a local notification.
  void subscribeNews() {
    final client = Supabase.instance.client;
    _newsChannel?.unsubscribe();
    _newsChannel = client.channel('news');

    _newsChannel!.onBroadcast(event: 'news_created', callback: (payload) async {
      final title = (payload['title'] as String?)?.trim();
      final content = (payload['content'] as String?)?.trim();
      if (title == null || content == null) return;
      await _showNotification(
        id: _uniqueId(),
        title: 'Nova notícia: $title',
        body: content,
        payload: 'news',
      );
    });

    _newsChannel!.subscribe();
  }

  /// Subscribe to per-user inbox channel for chat messages.
  void subscribeInbox({required int userId}) {
    final client = Supabase.instance.client;
    _inboxChannel?.unsubscribe();
    _inboxChannel = client.channel('inbox_$userId');

    _inboxChannel!.onBroadcast(event: 'chat_message', callback: (payload) async {
      // Expect { sender_username, message, chat_room_id }
      final sender = (payload['sender_username'] as String?) ?? 'Mensagem';
      final message = (payload['message'] as String?) ?? '';
      await _showNotification(
        id: _uniqueId(),
        title: sender,
        body: message,
        payload: 'chat',
      );
    });

    _inboxChannel!.subscribe();
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Geral',
      channelDescription: 'Notificações gerais do app',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _fln.show(id, title, body, details, payload: payload);
  }

  int _counter = 0;
  int _uniqueId() => DateTime.now().millisecondsSinceEpoch.remainder(1 << 31) + (_counter++);

  Future<void> dispose() async {
    await _newsChannel?.unsubscribe();
    await _inboxChannel?.unsubscribe();
  }
}

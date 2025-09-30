import 'dart:io';

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles local notifications and Realtime subscriptions for news and chat inbox.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  RealtimeChannel? _newsChannel;
  RealtimeChannel? _inboxChannel;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Inicialização
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _fln.initialize(initSettings);

    // Permissões
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Canal padrão para Android 8+
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'default',
        'Notificações',
        description: 'Notificações gerais do app',
        importance: Importance.high,
      ));
    } else if (Platform.isIOS) {
      await _fln
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> showSimple({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default',
      'Notificações',
      channelDescription: 'Notificações gerais do app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.show(id, title, body, details, payload: payload);
  }

  Future<void> subscribeNews() async {
    final client = Supabase.instance.client;
    _newsChannel ??= client
        .channel('public:news')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'news',
          callback: (payload) {
            final data = payload.newRecord;
            final title = (data['titulo'] ?? 'Nova notícia').toString();
            final body = (data['resumo'] ?? '').toString();
            showSimple(title: title, body: body);
          },
        )
        .subscribe();
  }

  void subscribeInbox({required int userId}) {
    final client = Supabase.instance.client;
    _inboxChannel ??= client
        .channel('public:inbox')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'inbox',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId.toString(),
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final title = (data['from_name'] ?? 'Nova mensagem').toString();
            final body = (data['text'] ?? '').toString();
            showSimple(title: title, body: body);
          },
        )
        .subscribe();
  }

  Future<void> dispose() async {
    await _newsChannel?.unsubscribe();
    _newsChannel = null;
    await _inboxChannel?.unsubscribe();
    _inboxChannel = null;
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/crud/login.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/mural.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/visualizar_pagamento_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_flutter/user_data.dart';
import 'package:app_flutter/notifications/notification_service.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

bool isLoggedIn = false;

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // Inicializa notificações e assina Realtime
  await NotificationService.instance.init();
  await NotificationService.instance.subscribeToRealtime(Supabase.instance.client);
  
  // Verifica se há credenciais salvas
  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('email');
  final savedName = prefs.getString('nome_usuario');
  final savedUserType = prefs.getInt('tipo_usuario');
  final savedUserId = prefs.getString('id_usuario');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewsData()),
        ChangeNotifierProvider(create: (context) {
          final profile = UserProfileData();
          if (savedName != null) profile.updateName(savedName);
          if (savedUserType != null) profile.updateUserType(savedUserType);
          return profile;
        }),
        ChangeNotifierProvider(create: (context) => PaymentData()),
        ChangeNotifierProvider(create: (context) {
          final ud = UserData();
          // hydrate from saved values
          if (savedUserId != null && savedName != null) {
            // setUser persists too
            ud.setUser(savedUserId, savedName);
          } else {
            // fallback: attempt load
            ud.loadFromPrefs();
          }
          return ud;
        }),
      ],
      child: AppRoot(
        isLoggedIn: savedEmail != null && savedName != null && savedUserType != null,
      ),
    ),
  );
}

class AppRoot extends StatefulWidget {
  final bool isLoggedIn;
  const AppRoot({super.key, required this.isLoggedIn});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    // Initialize local notifications
    NotificationService.instance.init().then((_) {
      // Subscribe to global news channel
      NotificationService.instance.subscribeNews();
      // Attach inbox subscription for current user if available
      final userIdStr = context.read<UserData>().userId;
      final userId = int.tryParse(userIdStr ?? '');
      if (userId != null) {
        NotificationService.instance.subscribeInbox(userId: userId);
      }
    });

    // Listen to user changes and (re)subscribe inbox channel accordingly
    context.read<UserData>().addListener(_onUserChanged);
  }

  void _onUserChanged() {
    final userIdStr = context.read<UserData>().userId;
    final userId = int.tryParse(userIdStr ?? '');
    if (userId != null) {
      NotificationService.instance.subscribeInbox(userId: userId);
    }
  }

  @override
  void dispose() {
    context.read<UserData>().removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: widget.isLoggedIn ? const PaginaPrincipal() : const Login(),
    );
  }
}

class NotificationService {

  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  Future<void> init() async {
    // Initialization logic
  }

  void subscribeNews() {
    // Subscribe to global news channel
  }

  void subscribeInbox({required int userId}) {
    // Subscribe to user-specific inbox channel
  }

  Future<void> subscribeToRealtime(SupabaseClient client) async {
    // Add logic to subscribe to Supabase Realtime
  }
}

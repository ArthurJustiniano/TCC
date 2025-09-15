import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/crud/login.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/mural.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/visualizar_pagamento_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Verifica se há credenciais salvas
  final prefs = await SharedPreferences.getInstance();
  final savedEmail = prefs.getString('email');
  final savedName = prefs.getString('nome_usuario');
  final savedUserType = prefs.getInt('tipo_usuario');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewsData()),
        ChangeNotifierProvider(create: (context) => UserProfileData()
          ..updateName(savedName ?? '')
          ..userType = savedUserType ?? 1),
        ChangeNotifierProvider(create: (context) => PaymentData()),
      ],
      child: MaterialApp(
        home: savedEmail != null && savedName != null && savedUserType != null
            ? const PaginaPrincipal()
            : const Login(),
      ),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/crud/login.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/mural.dart';
import 'package:app_flutter/user_profile_data.dart';

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
  
  // Garante que os widgets do Flutter estão prontos
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Firebase 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

if (isLoggedIn == false) {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewsData()),
        ChangeNotifierProvider(create: (context) => UserProfileData()),
      ],
      child: const Login(),
    ),
  );
} else {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewsData()),
        ChangeNotifierProvider(create: (context) => UserProfileData()),
      ],
      child: const PaginaPrincipal(),
    ),
  );
}
}
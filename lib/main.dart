import 'package:app_flutter/user_profile_data.dart';
import 'package:flutter/material.dart';
import 'package:app_flutter/localizacao.dart' as localizacao;
import 'package:app_flutter/carteirinha.dart' as carteirinha;
import 'package:app_flutter/chatpage.dart' as chatpage;
import 'package:app_flutter/maispage.dart' as maispage;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/crud/login.dart';

bool isLoggedIn = false; 

Future<void> main() async {
  // Garante que os widgets do Flutter estão prontos
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

if(isLoggedIn == false) {
  runApp(const Login());
}else{
  runApp(const PaginaPrincipal());
}
}
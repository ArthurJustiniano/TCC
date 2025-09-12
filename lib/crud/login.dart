import 'package:app_flutter/crud/cadastro.dart';
import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/user_data.dart';
import 'package:app_flutter/crud/esqueci_senha.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

// Emulador Android conversando com XAMPP local:
const String kApiBase = 'http://10.0.2.2/tcc_api'; 
// Se for aparelho físico, use o IP da sua máquina na rede, ex: 'http://192.168.0.10/tcc_api'
final Uri kLoginUrl = Uri.parse('$kApiBase/login.php');

final supabase = Supabase.instance.client;

Future<Map<String, dynamic>> login(String email, String senha) async {
  try {
    final response = await supabase
        .from('usuario') // Corrigido para letras minúsculas
        .select()
        .eq('email_usuario', email)
        .eq('senha_usuario', senha)
        .maybeSingle();

    if (response == null || response.isEmpty) {
      return {'status': 'error', 'message': 'Credenciais inválidas. Tente novamente.'};
    }

    return {
      'status': 'success',
      'message': 'Login realizado com sucesso!',
      'id_usuario': response['id_usuario'],
      'nome_usuario': response['nome_usuario']
    };
  } catch (e) {
    debugPrint('Erro no login: $e');
    return {'status': 'error', 'message': 'Erro de conexão: $e'};
  }
}

class LoginData extends ChangeNotifier {
  String email = '';
  String password = '';
  bool obscurePassword = true;

  void updateEmail(String newEmail) {
    email = newEmail;
    notifyListeners();
  }

  void updatePassword(String newPassword) {
    password = newPassword;
    notifyListeners();
  }

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginData()),
        ChangeNotifierProvider(create: (_) => UserData()),
      ],
      child: MaterialApp(
        title: 'Login App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.blue.shade100,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 16.0,
            ),
            labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ),
        home: const LoginPage(),
        routes: {
          "/home": (context) => const PaginaPrincipal(),
        },

      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade200,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'RotaFácil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.directions_bus,
                    size: 48.0,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Provider.of<LoginData>(context, listen: false)
                        .validateEmail,
                    onChanged: (value) =>
                        Provider.of<LoginData>(context, listen: false)
                            .updateEmail(value),
                  ),
                  const SizedBox(height: 20),
                  Consumer<LoginData>(
                    builder: (context, loginData, child) => TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            loginData.obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.blue,
                          ),
                          onPressed: loginData.toggleObscurePassword,
                        ),
                      ),
                      obscureText: loginData.obscurePassword,
                      validator: loginData.validatePassword,
                      onChanged: (value) => loginData.updatePassword(value),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Esqueci minha senha',
                        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      
                      ),
                    ),
                    onPressed: ()async {
                      if (_formKey.currentState!.validate()) {
                        Map<String, dynamic> data = await login(
                          context.read<LoginData>().email,
                          context.read<LoginData>().password,
                        );

                        final status = (data['status'] ?? '').toString().toLowerCase();
                        final msg = (data['message'] ?? 'Erro desconhecido').toString();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );

                        if (status == 'success') {
                          final userId = data['id_usuario'].toString();
                          final userName = data['nome_usuario'].toString();
                          Provider.of<UserData>(context, listen: false).setUser(userId, userName);
                          Navigator.pushReplacementNamed(context, "/home");
                        }
                      }
                    },
                    child: const Text('Logar'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2DAAF0),
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) => RegistrationData(),
                              child: const Cadastro(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Cadastrar')
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


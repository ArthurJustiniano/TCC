import 'package:app_flutter/crud/cadastro.dart';
import 'package:app_flutter/PaginaPrincipal.dart';
import 'package:app_flutter/user_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_flutter/crud/esqueci_senha_pergunta.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

// Emulador Android conversando com XAMPP local:
const String kApiBase = 'http://10.0.2.2/tcc_api'; 
// Se for aparelho físico, use o IP da sua máquina na rede, ex: 'http://192.168.0.10/tcc_api'
final Uri kLoginUrl = Uri.parse('$kApiBase/login.php');

final supabase = Supabase.instance.client;

Future<Map<String, dynamic>> login(String email, String senha, BuildContext context) async {
  try {
    final response = await supabase
        .from('usuario')
        .select()
        .eq('email_usuario', email)
        .eq('senha_usuario', senha)
        .maybeSingle();

    if (response == null || response.isEmpty) {
      return {'status': 'error', 'message': 'Credenciais inválidas. Tente novamente.'};
    }

    // Atualiza perfil completo (nome, tipo, email, telefone)
    final userName = response['nome_usuario'];
    final userType = response['tipo_usuario'];
    final userEmail = response['email_usuario'] ?? '';
    final userPhone = response['telefone'] ?? '';
    final userProfile = Provider.of<UserProfileData>(context, listen: false);
    userProfile.updateName(userName);
    userProfile.updateUserType(userType);
    userProfile.updateEmail(userEmail);
    if (userPhone.toString().isNotEmpty) {
      userProfile.updatePhone(userPhone);
    }

    // Salva as credenciais no shared_preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  await prefs.setString('nome_usuario', userName);
  await prefs.setInt('tipo_usuario', userType);
  await prefs.setString('telefone', userPhone ?? '');
    await prefs.setString('id_usuario', response['id_usuario'].toString());

    return {
      'status': 'success',
      'message': 'Login realizado com sucesso!',
      'id_usuario': response['id_usuario'],
      'nome_usuario': userName
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo e título
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RotaFácil',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sua jornada começa aqui',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Card de login
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Bem-vindo de volta!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entre com suas credenciais',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Campo Email
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: Provider.of<LoginData>(context, listen: false)
                                    .validateEmail,
                                onChanged: (value) =>
                                    Provider.of<LoginData>(context, listen: false)
                                        .updateEmail(value),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Senha
                            Consumer<LoginData>(
                              builder: (context, loginData, child) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey.shade500,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        loginData.obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: loginData.toggleObscurePassword,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                  obscureText: loginData.obscurePassword,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: loginData.validatePassword,
                                  onChanged: (value) => loginData.updatePassword(value),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Botão Login
                            Container(
                              height: 56,
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
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    if (_formKey.currentState!.validate()) {
                                      Map<String, dynamic> data = await login(
                                        context.read<LoginData>().email,
                                        context.read<LoginData>().password,
                                        context
                                      );

                                      final status = (data['status'] ?? '').toString().toLowerCase();
                                      final msg = (data['message'] ?? 'Erro desconhecido').toString();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(msg),
                                          backgroundColor: status == 'success' 
                                              ? Colors.green.shade600 
                                              : Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );

                                      if (status == 'success') {
                                        final userId = data['id_usuario'].toString();
                                        final userName = data['nome_usuario'].toString();
                                        await Provider.of<UserData>(context, listen: false).setUser(userId, userName);
                                        Navigator.pushReplacementNamed(context, "/home");
                                      }
                                    }
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Botão Cadastrar
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF667eea),
                                  width: 2,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
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
                                  child: const Center(
                                    child: Text(
                                      'Criar Conta',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF667eea),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Botão Esqueci minha senha
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.deepPurple.shade400,
                                    Colors.deepPurple.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EsqueciSenhaPerguntaPage(),
                                      ),
                                    );
                                  },
                                  child: const Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.quiz_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Esqueci minha senha',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Texto explicativo
                            Text(
                              'Recupere sua senha através de pergunta de segurança',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


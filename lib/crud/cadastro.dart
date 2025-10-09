import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

final supabase = Supabase.instance.client;

// Mantido por compatibilidade. Use cadastrarComTelefone.
Future<String> cadastrar(String nome, String email, String senha) async {
  return cadastrarComTelefone(nome, email, senha, '', '', '');
}

Future<String> cadastrarComTelefone(String nome, String email, String senha, String telefone, String perguntaSeguranca, String respostaSeguranca) async {
  try {
    await supabase
        .from('usuario')
        .insert({
          'nome_usuario': nome,
          'email_usuario': email,
          'senha_usuario': senha,
          'telefone': telefone,
          'pergunta_seguranca': perguntaSeguranca,
          'resposta_seguranca': respostaSeguranca,
          'tipo_usuario': 1,
          'pagamento_status': 'PENDENTE',
        });
    return 'Cadastro realizado com sucesso!';
  } catch (e) {
    debugPrint('Erro no cadastro: $e');
    String msg = 'Erro de conexão: $e';
    final lower = e.toString().toLowerCase();
    if (lower.contains('duplicate') || lower.contains('unique')) {
      msg = 'Email já cadastrado.';
    }
    return msg;
  }
}

class RegistrationData extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _password = '';
  String _phone = '';
  String _securityQuestion = '';
  String _securityAnswer = '';
  bool _obscureText = true;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get phone => _phone;
  String get securityQuestion => _securityQuestion;
  String get securityAnswer => _securityAnswer;
  bool get obscureText => _obscureText;

  set name(String value) {
    _name = value;
    notifyListeners();
  }

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  set password(String value) {
    _password = value;
    notifyListeners();
  }

  set phone(String value) {
    _phone = value;
    notifyListeners();
  }

  set securityQuestion(String value) {
    _securityQuestion = value;
    notifyListeners();
  }

  set securityAnswer(String value) {
    _securityAnswer = value;
    notifyListeners();
  }

  set obscureText(bool value) {
    _obscureText = value;
    notifyListeners();
  }

  bool validateEmail(String value) {
    // Basic email validation
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
  }
}

// CLASSE RENOMEADA E REESTRUTURADA
class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
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
                      padding: const EdgeInsets.all(20),
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
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'RotaFácil',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie sua conta e embarque nessa jornada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Card de cadastro
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
                              'Criar Nova Conta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preencha os dados abaixo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Campo Nome
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
                                  labelText: 'Nome Completo',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu nome.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  Provider.of<RegistrationData>(context, listen: false).name = value;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Telefone
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
                                  labelText: 'Telefone',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  hintText: '(11) 99999-9999',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu telefone.';
                                  }
                                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (digits.length < 8) {
                                    return 'Telefone inválido.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  Provider.of<RegistrationData>(context, listen: false).phone = value;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu email.';
                                  }
                                  if (!Provider.of<RegistrationData>(context, listen: false).validateEmail(value)) {
                                    return 'Por favor, insira um email válido.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  Provider.of<RegistrationData>(context, listen: false).email = value;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Senha
                            Consumer<RegistrationData>(
                              builder: (context, registrationData, child) => Container(
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
                                        registrationData.obscureText 
                                            ? Icons.visibility_outlined 
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () {
                                        registrationData.obscureText = !registrationData.obscureText;
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                  obscureText: registrationData.obscureText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, insira sua senha.';
                                    }
                                    if (value.length < 6) {
                                      return 'A senha deve ter pelo menos 6 caracteres.';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    Provider.of<RegistrationData>(context, listen: false).password = value;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Pergunta de Segurança
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Pergunta de Segurança',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.quiz_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2C3E50),
                                ),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Qual o nome do seu primeiro animal de estimação?',
                                    child: Flexible(
                                      child: Text(
                                        'Qual o nome do seu primeiro animal de estimação?',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Em que cidade você nasceu?',
                                    child: Text('Em que cidade você nasceu?'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Qual o nome da sua mãe?',
                                    child: Text('Qual o nome da sua mãe?'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Qual era o nome da sua primeira escola?',
                                    child: Flexible(
                                      child: Text(
                                        'Qual era o nome da sua primeira escola?',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Qual é o seu filme favorito?',
                                    child: Text('Qual é o seu filme favorito?'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, selecione uma pergunta de segurança.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  Provider.of<RegistrationData>(context, listen: false).securityQuestion = value ?? '';
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Campo Resposta de Segurança
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
                                  labelText: 'Resposta da Pergunta de Segurança',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  hintText: 'Digite sua resposta...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.security_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira a resposta da pergunta de segurança.';
                                  }
                                  if (value.length < 2) {
                                    return 'A resposta deve ter pelo menos 2 caracteres.';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  Provider.of<RegistrationData>(context, listen: false).securityAnswer = value;
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Botão Cadastrar
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
                                      debugPrint('Name: ${Provider.of<RegistrationData>(context, listen: false).name}');
                                      debugPrint('Email: ${Provider.of<RegistrationData>(context, listen: false).email}');
                                      debugPrint('Password: ${Provider.of<RegistrationData>(context, listen: false).password}');                 
                                      
                                      final reg = context.read<RegistrationData>();
                                      String mensagem = await cadastrarComTelefone(
                                        reg.name,
                                        reg.email,
                                        reg.password,
                                        reg.phone,
                                        reg.securityQuestion,
                                        reg.securityAnswer,
                                      );
                                    
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(mensagem),
                                          backgroundColor: mensagem.contains('sucesso') 
                                              ? Colors.green.shade600 
                                              : Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                      
                                      if (mensagem.contains('sucesso')) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Criar Conta',
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
                            
                            // Botão Voltar
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
                                    Navigator.pop(context);
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Voltar para o Login',
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
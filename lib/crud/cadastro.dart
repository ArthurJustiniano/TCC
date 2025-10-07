import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

final supabase = Supabase.instance.client;

// Mantido por compatibilidade. Use cadastrarComTelefone.
Future<String> cadastrar(String nome, String email, String senha) async {
  return cadastrarComTelefone(nome, email, senha, '');
}

Future<String> cadastrarComTelefone(String nome, String email, String senha, String telefone) async {
  try {
    await supabase
        .from('usuario')
        .insert({
          'nome_usuario': nome,
          'email_usuario': email,
          'senha_usuario': senha,
          'telefone': telefone,
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
  bool _obscureText = true;

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get phone => _phone;
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
    // AGORA RETORNA UM SCAFFOLD DIRETAMENTE
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 200, 213, 221),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'RotaFácil',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Icon(
                      Icons.directions_bus,
                      size: 48,
                      color: Color(0xFF6750A4),
                    ),
                    const Text(
                      'Cadastro',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide.none,
                        ),
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
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Telefone',
                        labelStyle: TextStyle(color: Colors.black),
                        hintText: '(DDD) 90000-0000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
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
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide.none,
                        ),
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
                    const SizedBox(height: 16.0),
                    Consumer<RegistrationData>(
                      builder: (context, registrationData, child) => TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 253, 253, 253),
                          labelText: 'senha',
                          labelStyle: TextStyle(color: Colors.black),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              registrationData.obscureText ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              registrationData.obscureText = !registrationData.obscureText;
                            },
                          ),
                        ),
                        obscureText: registrationData.obscureText,
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
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DAAF0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      onPressed: () async {
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
                          );
                        
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(mensagem)),
                          );
                        }
                      },
                      child: const Text('Cadastrar'),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2DAAF0),
                          minimumSize: const Size(double.infinity, 50),
                          
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Voltar para o Login'),
                        
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
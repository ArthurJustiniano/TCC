import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


Future<String> cadastrar(String nome, String email, String senha) async {
  var url = Uri.parse("http://192.168.0.108/tcc_api/cadastro.php"); // Substitua pelo URL do seu servidor

  var response = await http.post(url, body: {
    "nome_passageiro": nome,
    "email_passageiro": email,
    "senha_passageiro": senha,
  });

  final data = jsonDecode(response.body);

  return data["message"];
}

class RegistrationData extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _password = '';
  bool _obscureText = true;

  String get name => _name;
  String get email => _email;
  String get password => _password;
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
      backgroundColor: const Color(0xFFB4DEFF),
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
                      'Asseumir',
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
                        labelText: 'Email',
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
                          fillColor: Colors.white,
                          labelText: 'Password',
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
                          
                          String mensagem = await cadastrar(
                            context.read<RegistrationData>().name,
                            context.read<RegistrationData>().email,
                            context.read<RegistrationData>().password,
                          );
                        
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(mensagem)),
                          );
                        }
                      },
                      child: const Text('Cadastrar'),
                    ),
                    
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
                        Navigator.pop(context);
                      },
                      child: const Text('Voltar para o Login'),
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
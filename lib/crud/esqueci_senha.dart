import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

const supabaseUrl = 'https://mpfvazaqmuzxzhihfnwz.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wZnZhemFxbXV6eHpoaWhmbnd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxMDg3OTksImV4cCI6MjA3MjY4NDc5OX0.B-K7Ib_e77zIhTeh9-hoXc4dDJPvO7a9M66osO1jFXw";

//const String kApiBase = 'http://10.0.2.2/tcc_api'; ajuste conforme seu ambiente

String kApiBase = 'http://192.168.0.108/tcc_api';

final Uri kForgotUrl = Uri.parse('$kApiBase/esqueci_senha.php');
final Uri kResetUrl  = Uri.parse('$kApiBase/redefinir_senha.php');

final supabase = Supabase.instance.client;

Future<Map<String, String>> enviarCodigo(String email) async {
  try {
    debugPrint('Iniciando envio de código para: $email');

    final response = await supabase
        .from('usuario')
        .select('reset_code, email_usuario') // Adicionando mais campos para depuração
        .eq('email_usuario', email)
        .maybeSingle();

    debugPrint('Resposta do Supabase: $response');

    if (response == null || response.isEmpty) {
      debugPrint('Email não encontrado na tabela usuario.');
      return {'status': 'error', 'message': 'Email não encontrado.'};
    }

    // Gerar código de redefinição e atualizar no banco
    final resetCode = (100000 + (999999 - 100000) * (new DateTime.now().millisecondsSinceEpoch % 1000) / 1000).toInt().toString();
    debugPrint('Código gerado: $resetCode');

    final resetExpires = DateTime.now().add(Duration(minutes: 15)).toIso8601String();
    await supabase
        .from('usuario')
        .update({'reset_code': resetCode, 'reset_expires': resetExpires})
        .eq('email_usuario', email);

    debugPrint('Código atualizado no banco de dados.');

    // Enviar email com o código
    final Email emailToSend = Email(
      body: 'Seu código de redefinição de senha é: $resetCode',
      subject: 'Código de Redefinição de Senha',
      recipients: [email],
      isHTML: false,
    );

    await FlutterEmailSender.send(emailToSend);
    debugPrint('Email enviado com sucesso.');

    return {'status': 'success', 'message': 'Código enviado para o email.'};
  } catch (e) {
    debugPrint('Erro enviarCodigo: $e');
    return {'status': 'error', 'message': 'Erro de conexão: $e'};
  }
}

Future<String> redefinirSenha(String email, String codigo, String nova) async {
  try {
    final response = await supabase
        .from('usuario')
        .select('reset_code, reset_expires')
        .eq('email_usuario', email)
        .maybeSingle();

    if (response == null || response.isEmpty) {
      return 'Email não encontrado.';
    }

    if (response['reset_code'] != codigo) {
      return 'Código inválido.';
    }

    if (DateTime.parse(response['reset_expires']).isBefore(DateTime.now())) {
      return 'Código expirado.';
    }

    await supabase
        .from('usuario')
        .update({'senha_usuario': nova, 'reset_code': null, 'reset_expires': null})
        .eq('email_usuario', email);

    return 'sucesso';
  } catch (e) {
    debugPrint('Erro redefinirSenha: $e');
    return 'Erro de conexão';
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;

  void _sendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final result = await enviarCodigo(_emailController.text);
      setState(() {
        _isLoading = false;
      });
      if (result['status'] == 'success') {
        setState(() {
          _codeSent = true;
        });
        String message = result['message']!;
        if (result.containsKey('debug_code')) {
          message += ' Código: ${result['debug_code']}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']!)),
        );
      }
    }
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final result = await redefinirSenha(
        _emailController.text,
        _codeController.text,
        _passwordController.text,
      );
      setState(() {
        _isLoading = false;
      });
      if (result == 'sucesso') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esqueci minha senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  return null;
                },
              ),
              if (_codeSent)
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o código';
                    }
                    return null;
                  },
                ),
              if (_codeSent)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Nova Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a nova senha';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _codeSent ? _resetPassword : _sendCode,
                  child: Text(_codeSent ? 'Redefinir Senha' : 'Enviar Código'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

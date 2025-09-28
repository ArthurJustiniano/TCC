import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/user_profile_data.dart';

class AdminUserRegistrationPage extends StatefulWidget {
  const AdminUserRegistrationPage({super.key});

  @override
  State<AdminUserRegistrationPage> createState() => _AdminUserRegistrationPageState();
}

class _AdminUserRegistrationPageState extends State<AdminUserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedRole = 2; // 2 = Motorista, 3 = Administrador
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final client = Supabase.instance.client;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
  final tipo = _selectedRole; // 2 or 3
  final telefone = _phoneController.text.trim();

    try {
      // Para motoristas/admins, pagamento_status pode ser nulo
      final payload = {
        'nome_usuario': name,
        'email_usuario': email,
        'senha_usuario': password,
        'telefone': telefone.isEmpty ? null : telefone,
        'tipo_usuario': tipo,
        // Não incluir 'pagamento_status' para 2/3; manter NULL por padrão
      };
      await client.from('usuario').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso.')),
        );
        _formKey.currentState!.reset();
        _selectedRole = 2;
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
        setState(() {});
      }
    } catch (e) {
      String message = 'Erro ao cadastrar: $e';
      // Dica amigável em caso de email duplicado (chave única)
      final err = e.toString().toLowerCase();
      if (err.contains('unique') || err.contains('duplicate')) {
        message = 'Email já cadastrado. Escolha outro.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<UserProfileData>().userType;
    final isAdmin = userType == 3;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro de Usuários'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.redAccent, size: 48),
                SizedBox(height: 12),
                Text(
                  'Acesso restrito. Apenas administradores podem acessar esta página.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Motorista/Admin'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: const Color(0xFFE8EEF3),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Informações do Usuário',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                      hintText: '(DDD) 90000-0000'
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o telefone.';
                      }
                      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 8) return 'Telefone inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o email.';
                      }
                      final email = value.trim();
                      final regex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
                      if (!regex.hasMatch(email)) {
                        return 'Email inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha.';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de Usuário',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('Motorista')),
                      DropdownMenuItem(value: 3, child: Text('Administrador')),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: const Text('Cadastrar'),
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

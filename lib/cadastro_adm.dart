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
  final _respostaController = TextEditingController();
  
  int _selectedRole = 2; // 2 = Motorista, 3 = Administrador
  String? _selectedSecurityQuestion;
  bool _submitting = false;
  bool _obscurePassword = true;

  // Lista de perguntas de segurança pré-definidas
  final List<String> _securityQuestions = [
    'Qual é o nome da sua primeira escola?',
    'Qual é o nome do seu primeiro animal de estimação?',
    'Em que cidade você nasceu?',
    'Qual é o nome de solteira da sua mãe?',
    'Qual é sua comida favorita?',
    'Qual é o nome da rua onde você cresceu?',
    'Qual é seu filme favorito?',
    'Qual é o nome do seu melhor amigo de infância?',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedSecurityQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma pergunta de segurança'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _submitting = true);

    final client = Supabase.instance.client;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final tipo = _selectedRole; // 2 or 3
    final telefone = _phoneController.text.trim();
    final resposta = _respostaController.text.trim();

    try {
      // Para motoristas/admins, pagamento_status pode ser nulo
      final payload = {
        'nome_usuario': name,
        'email_usuario': email,
        'senha_usuario': password,
        'telefone': telefone.isEmpty ? null : telefone,
        'tipo_usuario': tipo,
        'pergunta_seguranca': _selectedSecurityQuestion,
        'resposta_seguranca': resposta,
        // Não incluir 'pagamento_status' para 2/3; manter NULL por padrão
      };
      await client.from('usuario').insert(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _formKey.currentState!.reset();
        _selectedRole = 2;
        _selectedSecurityQuestion = null;
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();
        _respostaController.clear();
        setState(() {});
      }
    } catch (e) {
      String message = 'Erro ao cadastrar: $e';
      // Dica amigável em caso de email duplicado (chave única)
      final err = e.toString().toLowerCase();
      if (err.contains('unique') || err.contains('duplicate')) {
        message = '⚠️ Email já cadastrado. Escolha outro.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade600, Colors.blue.shade900],
            ),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: Colors.white, size: 80),
                  SizedBox(height: 24),
                  Text(
                    'Acesso Restrito',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Apenas administradores podem acessar esta página',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade100,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
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
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.indigo.shade600],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cadastro de Usuário',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    'Motoristas e Administradores',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Informações Pessoais
                        _buildSectionTitle('👤 Informações Pessoais'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nome Completo',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome completo';
                            }
                            if (value.trim().length < 3) {
                              return 'Nome deve ter pelo menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Telefone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          hint: '(11) 99999-9999',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o telefone';
                            }
                            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length < 10) return 'Telefone inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Acesso e Segurança
                        _buildSectionTitle('🔐 Acesso e Segurança'),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o email';
                            }
                            final email = value.trim();
                            final regex = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}");
                            if (!regex.hasMatch(email)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tipo de Usuário
                        _buildSectionTitle('👨‍💼 Tipo de Usuário'),
                        const SizedBox(height: 16),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 2,
                                child: Text('🚌 Motorista'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('👑 Administrador'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRole = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recuperação de Senha
                        _buildSectionTitle('🛡️ Recuperação de Senha'),
                        const SizedBox(height: 16),
                        
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedSecurityQuestion,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.help_outline),
                              hintText: 'Selecione uma pergunta de segurança',
                            ),
                            items: _securityQuestions.map((question) {
                              return DropdownMenuItem(
                                value: question,
                                child: Text(
                                  question,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedSecurityQuestion = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _respostaController,
                          label: 'Resposta de Segurança',
                          icon: Icons.key_outlined,
                          hint: 'Digite sua resposta',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe a resposta de segurança';
                            }
                            if (value.trim().length < 2) {
                              return 'Resposta muito curta';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Botão de Cadastro
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.indigo.shade600],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1, color: Colors.white),
                            label: Text(
                              _submitting ? 'Cadastrando...' : 'Cadastrar Usuário',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

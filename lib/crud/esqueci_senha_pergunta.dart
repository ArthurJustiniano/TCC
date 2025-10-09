import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EsqueciSenhaPerguntaPage extends StatefulWidget {
  const EsqueciSenhaPerguntaPage({super.key});

  @override
  State<EsqueciSenhaPerguntaPage> createState() => _EsqueciSenhaPerguntaPageState();
}

class _EsqueciSenhaPerguntaPageState extends State<EsqueciSenhaPerguntaPage> {
  final _emailController = TextEditingController();
  final _respostaController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  String? _perguntaSeguranca;
  bool _perguntaCarregada = false;
  bool _respostaCorreta = false;
  bool _isLoading = false;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _respostaController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _buscarPergunta() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Digite um email válido', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
        .from('usuario')
        .select('pergunta_seguranca')
        .eq('email_usuario', email)
        .maybeSingle();
        
      if (response == null || response['pergunta_seguranca'] == null || response['pergunta_seguranca'].toString().trim().isEmpty) {
        _showMessage('Email não encontrado ou usuário sem pergunta de segurança cadastrada', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      setState(() {
        _perguntaSeguranca = response['pergunta_seguranca'];
        _perguntaCarregada = true;
        _isLoading = false;
      });
      
      _showMessage('Pergunta encontrada! Responda para continuar.');
      
    } catch (e) {
      _showMessage('Erro ao buscar pergunta: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarResposta() async {
    final email = _emailController.text.trim();
    final resposta = _respostaController.text.trim();
    
    if (resposta.isEmpty) {
      _showMessage('Digite a resposta da pergunta de segurança', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
        .from('usuario')
        .select('resposta_seguranca')
        .eq('email_usuario', email)
        .maybeSingle();
        
      if (response == null || response['resposta_seguranca'] == null) {
        _showMessage('Erro ao verificar resposta', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      final respostaBanco = response['resposta_seguranca'].toString().toLowerCase().trim();
      final respostaUsuario = resposta.toLowerCase().trim();
      
      if (respostaBanco == respostaUsuario) {
        setState(() {
          _respostaCorreta = true;
          _isLoading = false;
        });
        _showMessage('Resposta correta! Agora defina uma nova senha.');
      } else {
        _showMessage('Resposta incorreta. Tente novamente.', isError: true);
        setState(() => _isLoading = false);
      }
      
    } catch (e) {
      _showMessage('Erro ao verificar resposta: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarSenha() async {
    final email = _emailController.text.trim();
    final novaSenha = _novaSenhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();
    
    if (novaSenha.isEmpty || confirmarSenha.isEmpty) {
      _showMessage('Preencha ambos os campos de senha', isError: true);
      return;
    }
    
    if (novaSenha.length < 6) {
      _showMessage('A senha deve ter pelo menos 6 caracteres', isError: true);
      return;
    }
    
    if (novaSenha != confirmarSenha) {
      _showMessage('As senhas não coincidem', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client
        .from('usuario')
        .update({'senha_usuario': novaSenha})
        .eq('email_usuario', email);
        
      _showMessage('Senha alterada com sucesso!');
      setState(() => _isLoading = false);
      
      // Aguarda um pouco para mostrar a mensagem e volta para login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      _showMessage('Erro ao alterar senha: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Recuperar Senha',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de informação
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue.shade600, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Recuperação por Pergunta de Segurança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite seu email para visualizar sua pergunta de segurança',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Campo Email
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _emailController,
                enabled: !_perguntaCarregada,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Digite seu email cadastrado',
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.deepPurple.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.all(20),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão Buscar Pergunta
            if (!_perguntaCarregada)
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _buscarPergunta,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Buscar Pergunta de Segurança',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            
            // Pergunta de Segurança
            if (_perguntaCarregada) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.quiz_outlined, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Pergunta de Segurança:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _perguntaSeguranca ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Resposta
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _respostaController,
                  enabled: !_respostaCorreta,
                  decoration: InputDecoration(
                    labelText: 'Sua Resposta',
                    hintText: 'Digite a resposta da pergunta acima',
                    prefixIcon: Icon(Icons.quiz_outlined, color: Colors.orange.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botão Verificar Resposta
              if (!_respostaCorreta)
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _verificarResposta,
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Verificar Resposta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
            
            // Campos de Nova Senha
            if (_respostaCorreta) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Resposta Verificada!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agora defina sua nova senha',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Nova Senha
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _novaSenhaController,
                  obscureText: _obscureNovaSenha,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    hintText: 'Digite sua nova senha (mín. 6 caracteres)',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNovaSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () => setState(() => _obscureNovaSenha = !_obscureNovaSenha),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Confirmar Senha
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _confirmarSenhaController,
                  obscureText: _obscureConfirmarSenha,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    hintText: 'Digite novamente sua nova senha',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () => setState(() => _obscureConfirmarSenha = !_obscureConfirmarSenha),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Botão Alterar Senha
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _alterarSenha,
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Alterar Senha',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

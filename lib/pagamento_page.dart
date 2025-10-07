import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

// Wrapper que garante acesso a PASSAGEIROS (1) e ADMINISTRADORES (3). Bloqueia apenas motoristas (2).
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileData>(
      builder: (context, userProfileData, child) {
        try {
          debugPrint('PaymentPage: Acessando UserProfileData via Consumer...');
          final userType = userProfileData.userType;
          debugPrint('PaymentPage: userType = $userType');
          
          if (userType == 2) {
            debugPrint('PaymentPage: Bloqueando acesso para motorista (userType = 2)');
            return _buildAccessDeniedScreen();
          }
          
          debugPrint('PaymentPage: Permitindo acesso, redirecionando para PaymentMethodsScreen');
          return const PaymentMethodsScreen();
        } catch (e, stackTrace) {
          debugPrint('PaymentPage: ERRO CRÍTICO: $e');
          debugPrint('PaymentPage: StackTrace: $stackTrace');
          return _buildErrorScreen(context, e);
        }
      },
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pagamentos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone com animação sutil
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200.withOpacity(0.6),
                        spreadRadius: 8,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.no_accounts,
                    size: 72,
                    color: Colors.orange.shade500,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Card principal
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Acesso Restrito',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Esta funcionalidade está disponível apenas para passageiros e administradores.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7F8C8D),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Informações adicionais
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Precisa de ajuda?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entre em contato com o administrador para obter acesso às funcionalidades de pagamento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade600,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, dynamic error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Erro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE53935),
                Color(0xFFD32F2F),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFFFEBEE),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de erro com animação
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade200.withOpacity(0.6),
                        spreadRadius: 8,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 72,
                    color: Colors.red.shade500,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Card principal do erro
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Oops! Algo deu errado',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Detalhes do erro
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bug_report,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Detalhes do Erro:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Botão voltar modernizado
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade200.withOpacity(0.4),
                              spreadRadius: 0,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Voltar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Informações de suporte
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.support_agent,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Precisa de ajuda?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Se o problema persistir, entre em contato com nossa equipe de suporte técnico.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade600,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _loading = true;
  String? _error;
  String _instruction = '';
  String _amountText = '';
  bool _isEditing = false;
  final _instructionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _instructionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('PaymentMethodsScreen: initState chamado');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstruction();
    });
  }

  Future<void> _loadInstruction() async {
    if (!mounted) {
      debugPrint('PaymentMethodsScreen: Widget não está montado, cancelando _loadInstruction');
      return;
    }
    
    debugPrint('PaymentMethodsScreen: _loadInstruction iniciado');
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      debugPrint('PaymentMethodsScreen: Fazendo query para payment_info');
      final row = await Supabase.instance.client
          .from('payment_info')
          .select('id, content, amount_content')
          .eq('id', 1)
          .maybeSingle();
          
      if (!mounted) {
        debugPrint('PaymentMethodsScreen: Widget desmontado durante a query');
        return;
      }
      
      if (row == null) {
        debugPrint('PaymentMethodsScreen: Nenhuma row encontrada, criando dados padrão');
        const defaultText = 'CHAVE PIX: exemplo@provedor.com\n(Altere este texto no painel de admin)';
        const defaultAmount = 'Valor mensal: R\$ 120,50';
        await Supabase.instance.client.from('payment_info').upsert({'id': 1, 'content': defaultText, 'amount_content': defaultAmount});
        
        if (!mounted) return;
        
        _instruction = defaultText;
        _amountText = defaultAmount;
      } else {
        debugPrint('PaymentMethodsScreen: Dados carregados com sucesso');
        _instruction = (row['content'] as String?)?.trim() ?? '';
        _amountText = (row['amount_content'] as String?)?.trim() ?? 'Valor mensal: (não definido)';
      }
    } catch (e) {
      debugPrint('PaymentMethodsScreen: Erro ao carregar dados: $e');
      final msg = e.toString();
      if (msg.contains('payment_info') && (msg.contains('not exist') || msg.contains('does not exist'))) {
        debugPrint('PaymentMethodsScreen: Tabela payment_info não existe, usando fallback');
        _instruction = 'CHAVE PIX: exemplo@provedor.com\n(Tabela payment_info ainda não foi criada. Admin: criar tabela e linha id=1)';
        _amountText = 'Valor mensal: R\$ 0,00';
        _error = null; // não trata como erro bloqueante
      } else {
        debugPrint('PaymentMethodsScreen: Erro real: $e');
        _error = 'Falha ao carregar instruções: $e';
      }
    } finally {
      debugPrint('PaymentMethodsScreen: Finalizando _loadInstruction, mounted: $mounted');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final newInstruction = _instructionController.text.trim();
      final newAmount = _amountController.text.trim();
      
      await Supabase.instance.client
          .from('payment_info')
          .upsert({
            'id': 1,
            'content': newInstruction,
            'amount_content': newAmount
          });
      
      if (!mounted) return;
      
      _instruction = newInstruction;
      _amountText = newAmount;
      _isEditing = false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Configurações salvas com sucesso!',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar alterações: $e');
      if (mounted) {
        _error = 'Erro ao salvar: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Erro ao salvar alterações',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _instructionController.text = _instruction;
      _amountController.text = _amountText;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PaymentMethodsScreen: build() chamado, _loading: $_loading, _error: $_error');
    
    return Consumer<UserProfileData>(
      builder: (context, userProfileData, child) {
        final isAdmin = userProfileData.userType == 3;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Pagamentos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1976D2),
                    Color(0xFF42A5F5),
                  ],
                ),
              ),
            ),
            elevation: 0,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F7FA),
                  Color(0xFFE8EEF2),
                ],
              ),
            ),
            child: SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Card(
                            elevation: 6,
                            margin: const EdgeInsets.all(24),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _loadInstruction(),
                                    child: const Text('Tentar Novamente'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Header com animação sutil
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.shade100.withOpacity(0.5),
                                            spreadRadius: 8,
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        size: 40,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Central de Pagamentos',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A237E),
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gerencie seus pagamentos de forma rápida e segura',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Card principal com gradiente melhorado
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                      Color(0xFF6B73FF),
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea).withOpacity(0.4),
                                      spreadRadius: 0,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.credit_card,
                                          size: 42,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Informações de Pagamento',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _amountText,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.green.shade300,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Pagamento Seguro',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Card PIX modernizado
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      spreadRadius: 0,
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header do PIX com ícone moderno
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.teal.shade400,
                                              Colors.teal.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.pix,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'PIX Instantâneo',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Transferência imediata e gratuita',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Container das instruções melhorado
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFFF8F9FA),
                                              Colors.blue.shade50.withOpacity(0.5),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.blue.shade100,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.blue.shade600,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Instruções para Pagamento',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                _instruction.isEmpty ? 'Carregando instruções...' : _instruction,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade800,
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Botão copiar modernizado
                                      if (_instruction.isNotEmpty) ...[
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.teal.shade400,
                                                Colors.teal.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.teal.shade200.withOpacity(0.4),
                                                spreadRadius: 0,
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () async {
                                                await Clipboard.setData(ClipboardData(text: _instruction));
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          const Text(
                                                            'Instruções copiadas com sucesso!',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor: Colors.green.shade600,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      margin: const EdgeInsets.all(16),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.content_copy,
                                                      color: Colors.white,
                                                      size: 22,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Copiar Instruções PIX',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Painel Admin modernizado
                              if (isAdmin) ...[
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.shade100.withOpacity(0.6),
                                        spreadRadius: 0,
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header admin
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.orange.shade400,
                                                Colors.orange.shade600,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.admin_panel_settings,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Painel Administrativo',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Editar configurações de pagamento',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        if (!_isEditing) ...[
                                          // Modo visualização
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange.shade100,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  color: Colors.orange.shade600,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'Como administrador, você pode editar as instruções de pagamento e valores mostrados aos usuários.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.orange.shade800,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          
                                          // Botão para iniciar edição
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.orange.shade400,
                                                  Colors.orange.shade600,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.shade200.withOpacity(0.4),
                                                  spreadRadius: 0,
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(16),
                                                onTap: _startEditing,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 22,
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        'Editar Configurações',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else ...[
                                          // Modo edição
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Campo para editar valor
                                              Text(
                                                'Valor da Mensalidade',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller: _amountController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Ex: Valor mensal: R\$ 120,50',
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.all(16),
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              
                                              // Campo para editar instruções PIX
                                              Text(
                                                'Instruções de Pagamento PIX',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller: _instructionController,
                                                  maxLines: 6,
                                                  decoration: InputDecoration(
                                                    hintText: 'Digite as instruções de pagamento PIX...\nEx: CHAVE PIX: exemplo@email.com\nTitular: Nome Completo\nBanco: Banco do Brasil',
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.all(16),
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              
                                              // Botões de ação
                                              Row(
                                                children: [
                                                  // Botão Cancelar
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(12),
                                                          onTap: _cancelEditing,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(
                                                                  Icons.close,
                                                                  color: Colors.grey.shade600,
                                                                  size: 20,
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  'Cancelar',
                                                                  style: TextStyle(
                                                                    color: Colors.grey.shade600,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  
                                                  // Botão Salvar
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            Colors.green.shade400,
                                                            Colors.green.shade600,
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.green.shade200.withOpacity(0.4),
                                                            spreadRadius: 0,
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(12),
                                                          onTap: _loading ? null : _saveChanges,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                if (_loading) ...[
                                                                  const SizedBox(
                                                                    width: 20,
                                                                    height: 20,
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth: 2,
                                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                                    ),
                                                                  ),
                                                                ] else ...[
                                                                  const Icon(
                                                                    Icons.save,
                                                                    color: Colors.white,
                                                                    size: 20,
                                                                  ),
                                                                ],
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  _loading ? 'Salvando...' : 'Salvar',
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              
                              // Footer com informações de segurança
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.security,
                                          color: Colors.green.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Transações Seguras',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Seus dados estão protegidos com criptografia de ponta a ponta. Todos os pagamentos são processados com segurança.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
}
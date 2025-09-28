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
    final userType = context.watch<UserProfileData>().userType;
    if (userType == 2) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pagamentos'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Acesso restrito a passageiros e administradores.',
            style: TextStyle(fontSize: 16, color: Colors.redAccent),
          ),
        ),
      );
    }
    return const PaymentMethodsScreen();
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

  @override
  void initState() {
    super.initState();
    _loadInstruction();
  }

  Future<void> _loadInstruction() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final row = await Supabase.instance.client
          .from('payment_info')
          .select('id, content, amount_content')
          .eq('id', 1)
          .maybeSingle();
      if (row == null) {
        // tenta criar default
        const defaultText = 'CHAVE PIX: exemplo@provedor.com\n(Altere este texto no painel de admin)';
        const defaultAmount = 'Valor mensal: R\$ 120,50';
        await Supabase.instance.client.from('payment_info').upsert({'id': 1, 'content': defaultText, 'amount_content': defaultAmount});
        _instruction = defaultText;
        _amountText = defaultAmount;
      } else {
        _instruction = (row['content'] as String?)?.trim() ?? '';
        _amountText = (row['amount_content'] as String?)?.trim() ?? 'Valor mensal: (não definido)';
      }
    } catch (e) {
      final msg = e.toString();
      // Se a tabela não existir ainda, fornece fallback e instrução para o admin criar.
      if (msg.contains('payment_info') && (msg.contains('not exist') || msg.contains('does not exist'))) {
        _instruction = 'CHAVE PIX: exemplo@provedor.com\n(Tabela payment_info ainda não foi criada. Admin: criar tabela e linha id=1)';
        _amountText = 'Valor mensal: R\$ 0,00';
        _error = null; // não trata como erro bloqueante
      } else {
        _error = 'Falha ao carregar instruções: $e';
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyInstruction() async {
    if (_instruction.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _instruction));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto copiado para a área de transferência.')),
      );
    }
  }

  final _editController = TextEditingController();
  final _amountController = TextEditingController();
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProfileData>().userType == 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamentos'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _loading ? null : _loadInstruction,
            icon: const Icon(Icons.refresh),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Editar texto',
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _editing = true;
                        _editController.text = _instruction;
                        _amountController.text = _amountText;
                      });
                    },
              icon: const Icon(Icons.edit),
            )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Chave PIX:',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Carregando...')
              ] else if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loadInstruction,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                )
              ] else if (_editing) ...[
                TextField(
                  controller: _editController,
                  minLines: 4,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Instruções de pagamento',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Texto do valor (ex: Valor mensal: R\$ 120,50)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _editing = false;
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newText = _editController.text.trim();
                          final newAmount = _amountController.text.trim();
                          try {
                            await Supabase.instance.client.from('payment_info').upsert({'id': 1, 'content': newText, 'amount_content': newAmount});
                            setState(() {
                              _instruction = newText;
                              _amountText = newAmount;
                              _editing = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Instruções atualizadas.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Falha ao salvar: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: _copyInstruction,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toque para copiar',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _instruction.isEmpty ? 'Nenhuma instrução configurada.' : _instruction,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _amountText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Botão de "Abrir PIX / QR Code" removido conforme solicitado.
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Removido PaymentOption (Cartão) conforme solicitado.

class PixScreen extends StatelessWidget {
  const PixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<UserProfileData>().userType;
    if (userType == 2) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PIX'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text('Acesso restrito a passageiros e administradores.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIX'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Pague com PIX',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            // Exibe a imagem da pasta 'imagens'
            // Certifique-se de que o nome do arquivo está correto.
            Image.asset(
              'imagens/QRCode_placeholder.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Aponte a câmera do seu celular para o QR Code',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
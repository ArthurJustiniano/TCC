import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' as intl;
import 'package:intl/intl.dart';
import 'package:app_flutter/chatpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await intl.initializeDateFormatting('pt_BR', null);
  } catch (e) {
    print('Error initializing locale: $e');
    // Handle the error appropriately, e.g., by falling back to a default locale
  }
  runApp(const carteirinha_page());
}

class carteirinha_page extends StatelessWidget {
  const carteirinha_page({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carteirinha Digital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DigitalCardScreen(),
    );
  }
}

class DigitalCardScreen extends StatefulWidget {
  const DigitalCardScreen({super.key});

  @override
  State<DigitalCardScreen> createState() => _DigitalCardScreenState();
}

class _DigitalCardScreenState extends State<DigitalCardScreen> {
  final String userName = "Usuario Teste";
  final String cardId = "1234567890";
  List<bool> paymentStatus = List.generate(12, (index) => index < 7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteirinha Digital'),
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView( // Added SingleChildScrollView
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
                color: Colors.blue[400],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: $cardId',
                                style: const TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                          const Icon(Icons.directions_bus, size: 40, color: Colors.indigo),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Status de Pagamento Mensal:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          String month = '';
                          try {
                            // Certifique-se de que o locale 'pt_BR' foi inicializado no main()
                            month = DateFormat.MMM('pt_BR').format(DateTime(2024, index + 1));
                          } catch (e) {
                            debugPrint('Erro ao formatar a data: $e');
                            month = 'M${index + 1}'; // Valor de fallback
                          }
                          return MonthPaymentStatus(
                            month: month,
                            isPaid: paymentStatus[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MonthPaymentStatus extends StatelessWidget {
  const MonthPaymentStatus({super.key, required this.month, required this.isPaid});

  final String month;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPaid ? Colors.green[400] : Colors.red[400],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Icon(
              isPaid ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
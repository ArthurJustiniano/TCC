import 'package:flutter/material.dart';
import 'package:app_flutter/loc.passageiro.dart';

class BusAppHomePage extends StatefulWidget {
  const BusAppHomePage({super.key});

  @override
  State<BusAppHomePage> createState() => _BusAppHomePageState();
}

class _BusAppHomePageState extends State<BusAppHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localização em Tempo Real')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const OrangeBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [AvailableRoutesCard(), const SizedBox(height: 20)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrangeBanner extends StatelessWidget {
  const OrangeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // Corrigindo cor e texto do banner
      decoration: const BoxDecoration(color: Color.fromARGB(255, 41, 166, 216)),
      child: Column(
        children: const [
          Icon(Icons.directions_bus, size: 50, color: Colors.white),
          Text('RotaFácil', style: TextStyle(fontSize: 24, color: Colors.white)),
          Text(
            'Acompanhe em tempo real',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class AvailableRoutesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rotas Disponíveis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Explore todas as rotas disponíveis',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linhas em tempo real',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Atualizações a cada minuto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RouteExamplesPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Ver todas as rotas',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteExamplesPage extends StatelessWidget {
  const RouteExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas dos motoristas')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const OrangeBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rotas James',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            RouteExampleCard(
                              routeName: 'Rota 101 - Centro',
                              stops: const [
                                'Ponto Inicial: Terminal Central',
                                'Ponto 1: Rua XV de Novembro',
                                'Ponto 2: Praça Tiradentes',
                                'Ponto 3: Rua das Flores',
                                'Ponto Final: Shopping Estação',
                              ],
                            ),
                            const SizedBox(height: 20),
                            RouteExampleCard(
                              routeName: 'Rota 202 - Universitária',
                              stops: const [
                                'Ponto Inicial: Terminal Capão Raso',
                                'Ponto 1: UTFPR',
                                'Ponto 2: PUC',
                                'Ponto 3: UNICENP',
                                'Ponto Final: Universidade Positivo',
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // IMPORTANTE: O 'driverId' deve ser o UUID real do motorista
                                    // que está na sua tabela de usuários do Supabase.
                                    // O valor 'uuid-do-james-aqui' é um exemplo e precisa ser substituído.
                                    builder: (context) => const MapScreenForPassenger(
                                      driverId:
                                          'uuid-do-james-aqui', // <-- SUBSTITUA PELO UUID REAL
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ver Localização',
                                style: TextStyle(color: Color.fromARGB(255, 250, 250, 250)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rotas Leandro',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            RouteExampleCard(
                              routeName: 'Rota manhã',
                              stops: const [
                                'Ponto Inicial: ...',
                                'Ponto 1: Parque Das Flores, Caixa D`água',
                                'Ponto 2: Posto Chinão',
                                'Ponto 3: Livraria Balipa',
                                'Ponto Final: Tufi Madi',
                                'Ponto Final: Posto Irmãos Coragem',
                              ],
                            ),
                            const SizedBox(height: 20),
                            RouteExampleCard(
                              routeName: 'Rota Tarde',
                              stops: const [
                                'Ponto Inicial: Etec Philadelhpho Gouveia Neto',
                                'Ponto 1: Posto HM',
                                'Ponto 2: Tufi Madi',
                                'Ponto 3: Escola Wilson paschoal',
                                'Ponto 4: Cohab II',
                                'Ponto Final: Parque das Flores Caixa D`água',
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // IMPORTANTE: O 'driverId' deve ser o UUID real do motorista
                                    // que está na sua tabela de usuários do Supabase.
                                    // O valor 'uuid-do-leandro-aqui' é um exemplo e precisa ser substituído.
                                    builder: (context) => const MapScreenForPassenger(
                                      driverId:
                                          'uuid-do-leandro-aqui', // <-- SUBSTITUA PELO UUID REAL
                                    ),
                                  ),
                            
                                );
                              },
                              child: const Text(
                                'Ver Localização',
                                style: TextStyle(color: Color.fromARGB(255, 247, 247, 247)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteExampleCard extends StatelessWidget {
  final String routeName;
  final List<String> stops;

  const RouteExampleCard({
    super.key,
    required this.routeName,
    required this.stops,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Paradas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stops.map((stop) => Text('- $stop')).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
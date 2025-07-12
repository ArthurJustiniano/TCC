import 'package:app_flutter/map.page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BusData(),
      child: const MyApp(),
    ),
  );
}

class BusData extends ChangeNotifier {
  String _selectedRoute = 'Route 1';
  String get selectedRoute => _selectedRoute;

  final List<String> _availableRoutes = ['Route 1', 'Route 2', 'Route 3'];
  List<String> get availableRoutes => _availableRoutes;

  double _busLatitude = -23.5505;
  double _busLongitude = -46.6333;
  double get busLatitude => _busLatitude;
  double get busLongitude => _busLongitude;

  final Map<String, String> _estimatedArrivalTimes = {
    'Stop 1': '8:00 AM',
    'Stop 2': '8:15 AM',
    'Stop 3': '8:30 AM',
    'Stop 4': '8:45 AM',
    'Stop 5': '9:00 AM',
  };
  Map<String, String> get estimatedArrivalTimes => _estimatedArrivalTimes;

  void updateSelectedRoute(String? newRoute) {
    if (newRoute != null) {
      _selectedRoute = newRoute;
      notifyListeners();
    }
  }

  void updateBusLocation() {
    // Simulate fetching bus location (replace with actual API call)
    // For demonstration, we'll move the bus between predefined locations

    const locations = [
      {'latitude': -23.5475, 'longitude': -46.6361}, // Near Stop 1
      {'latitude': -23.5495, 'longitude': -46.6343}, // Between Stop 1 and 2
      {'latitude': -23.5515, 'longitude': -46.6325}, // Near Stop 2
      {'latitude': -23.5535, 'longitude': -46.6307}, // Between Stop 2 and 3
      {'latitude': -23.5555, 'longitude': -46.6289}, // Near Stop 3
    ];

    int locationIndex = DateTime.now().second % locations.length;

    _busLatitude = locations[locationIndex]['latitude']!;
    _busLongitude = locations[locationIndex]['longitude']!;

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Bus App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const BusAppHomePage(),
    );
  }
}

class BusAppHomePage extends StatefulWidget {
  const BusAppHomePage({super.key});

  @override
  State<BusAppHomePage> createState() => _BusAppHomePageState();
}

class _BusAppHomePageState extends State<BusAppHomePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initial update of bus location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusData>(context, listen: false).updateBusLocation();
    });

    // Update bus location every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      Provider.of<BusData>(context, listen: false).updateBusLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      decoration: const BoxDecoration(color: Colors.blue),
      child: Column(
        children: const [
          Icon(Icons.directions_bus, size: 50, color: Colors.white),
          Text('Asseumir', style: TextStyle(fontSize: 24, color: Colors.white)),
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
                                    builder: (context) => MapPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ver Localização do Ônibus',
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
                                    builder: (context) => MapPage(),
                                  ),
                            
                                );
                              },
                              child: const Text(
                                'Ver Localização do Ônibus',
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

class BusLocationPage extends StatelessWidget {
  final String driverName;
  const BusLocationPage({super.key, required this.driverName});

  @override
  Widget build(BuildContext context) {
    final busData = Provider.of<BusData>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Localização do Ônibus - $driverName')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            Text('Latitude: ${busData.busLatitude}'),
            Text('Longitude: ${busData.busLongitude}'),
            const SizedBox(height: 20),
            const Text(
              'Mapa da Rota',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GenericMap(
                latitude: busData.busLatitude,
                longitude: busData.busLongitude,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapPage()),
                );
              },
              child: const Text('Abrir Mapa Completo'),
            ),
          ],
        ),
      ),
    );
  }
}

class GenericMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const GenericMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder for a map implementation.
    // Replace this with a real map widget using a package like flutter_map or google_maps_flutter
    // For this example, we'll just display coordinates.
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Center(
        child: Text('Map: Latitude: $latitude, Longitude: $longitude'),
      ),
    );
  }
}
import 'dart:async';
import 'package:app_flutter/map.page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/user_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class RouteExamplesPage extends StatefulWidget {
  const RouteExamplesPage({super.key});

  @override
  State<RouteExamplesPage> createState() => _RouteExamplesPageState();
}

class _RouteExamplesPageState extends State<RouteExamplesPage> {
  // Função para buscar motoristas do Supabase
  Future<List<Map<String, dynamic>>> _fetchDrivers() async {
    try {
      // Assumindo que o tipo de usuário '2' é para motoristas. Ajuste se necessário.
      final response = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nome_usuario')
          .eq('tipo_usuario', 2);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erro ao buscar motoristas: $e');
      // Retorna uma lista vazia em caso de erro para não quebrar a UI.
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas dos motoristas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum motorista encontrado.'));
          }

          final drivers = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const OrangeBanner(),
                // Adiciona o botão de "Modo Motorista" se o usuário for um motorista
                Consumer<UserProfileData>(
                  builder: (context, userProfile, child) {
                    // Pega o ID do usuário logado pelo Provider
                    final loggedInUserId = Provider.of<UserData>(context, listen: false).userId;

                    if (userProfile.userType == 2 && loggedInUserId != null && loggedInUserId.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.drive_eta, color: Colors.white),
                          label: const Text('ATIVAR MODO MOTORISTA', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapPage(
                                  // O motorista usa o seu próprio ID para enviar a localização
                                  trackedUserId: loggedInUserId,
                                  isDriver: true, // Ativa o modo motorista
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Não mostra nada se não for motorista
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drivers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final driverName = driver['nome_usuario'] as String;
                      final driverId = driver['id_usuario'].toString();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Motorista: $driverName',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
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
                                      builder: (context) => MapPage(
                                        trackedUserId: driverId, // <- USA O UUID REAL
                                        isDriver: false,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Ver Localização',
                                  style: TextStyle(
                                      color:
                                          Color.fromARGB(255, 250, 250, 250)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  final String trackedUserId;
  final bool isDriver;

  const MapPage({
    required this.trackedUserId,
    required this.isDriver,
    Key? key,
  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  StreamSubscription<Position>? _positionStream;
  late GoogleMapController _mapController;
  final Map<String, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.isDriver) {
      _startLocationUpdates();
    } else {
      _startListeningToDriverLocations();
    }
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream().listen((Position position) async {
      try {
        await Supabase.instance.client.from('locations').upsert({
          'user_id': widget.trackedUserId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Erro ao atualizar localização: $e');
      }
    });
  }

  void _startListeningToDriverLocations() {
    Supabase.instance.client
        .from('locations')
        .stream(primaryKey: ['id'])
        .execute()
        .listen((data) {
      setState(() {
        _markers.clear();
        for (var location in data) {
          final marker = Marker(
            markerId: MarkerId(location['user_id'].toString()),
            position: LatLng(location['latitude'], location['longitude']),
            infoWindow: InfoWindow(title: 'Motorista ${location['user_id']}'),
          );
          _markers[location['user_id'].toString()] = marker;
        }
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: widget.isDriver
          ? Center(
              child: Text('Atualizando localização...'),
            )
          : GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers.values.toSet(),
              initialCameraPosition: const CameraPosition(
                target: LatLng(-3.7327, -38.5270), // Posição inicial (exemplo)
                zoom: 14,
              ),
            ),
    );
  }
}
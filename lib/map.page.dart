import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IDs dos marcadores
const String _userMarkerId = 'user_location';
const String _driverMarkerId = 'driver_location';

class MapPage extends StatefulWidget {
  // O ID do motorista (seja para rastrear ou para o próprio motorista enviar sua localização)
  final String trackedUserId;
  final bool isDriver;

  const MapPage({super.key, required this.trackedUserId, this.isDriver = false});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  // Posição inicial do mapa (ex: centro da cidade)
  final LatLng _initialCameraPosition = const LatLng(-23.550520, -46.633308); // São Paulo

  // Stream para o modo motorista
  StreamSubscription<Position>? _positionStreamSubscription;
  // Stream para o modo passageiro
  Stream<Map<String, dynamic>>? _locationStream;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Solicita permissão de localização para ambos os modos
    var status = await Permission.location.request();
    if (status.isGranted) {
      // 2. Inicia o modo correto (motorista ou passageiro)
      if (widget.isDriver) {
        _initializeDriverMode();
      } else {
        _initializePassengerMode();
      }
      // 3. Centraliza o mapa na localização do usuário (motorista ou passageiro)
      _centerOnUserLocation();
    } else {
      // Lida com a permissão negada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'A permissão de localização é necessária para usar o mapa.')),
        );
      }
    }
  }

  /// Configura o modo MOTORISTA: envia a localização para o Supabase.
  void _initializeDriverMode() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
      ),
    ).listen((Position position) async {
      // Atualiza o marcador no próprio mapa do motorista
      final driverLocation = LatLng(position.latitude, position.longitude);
      _updateMarker(
        Marker(
          markerId: const MarkerId(_driverMarkerId),
          position: driverLocation,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      // Envia a localização para o Supabase
      try {
        await Supabase.instance.client.from('locations').upsert({
          'user_id': widget.trackedUserId, // O ID do próprio motorista
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint(
            'Localização enviada: ${position.latitude}, ${position.longitude}');
      } catch (error) {
        debugPrint('Erro ao enviar localização: $error');
      }
    });
  }

  /// Configura o modo PASSAGEIRO: escuta a localização do Supabase.
  void _initializePassengerMode() {
    _locationStream = Supabase.instance.client
        .from('locations')
        .stream(primaryKey: ['user_id']).eq('user_id', widget.trackedUserId)
        .map((listOfMaps) {
      if (listOfMaps.isNotEmpty) {
        return listOfMaps.first;
      }
      return <String, dynamic>{};
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Centraliza o mapa na localização atual do usuário.
  void _centerOnUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      _updateMarker(
        Marker(
          markerId: const MarkerId(_userMarkerId),
          position: userLocation,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16.0));
    } catch (e) {
      debugPrint("Erro ao obter localização atual: $e");
    }
  }

  /// Atualiza o conjunto de marcadores na tela.
  void _updateMarker(Marker marker) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId == marker.markerId);
      _markers.add(marker);
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isDriver ? 'Modo Motorista' : 'Localização do Motorista'),
      ),
      body: widget.isDriver ? _buildDriverMap() : _buildPassengerMap(),
    );
  }

  /// Constrói o mapa para o PASSAGEIRO, usando um StreamBuilder para tempo real.
  Widget _buildPassengerMap() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _locationStream,
      builder: (context, snapshot) {
        // Começa com os marcadores atuais (ex: a própria posição do passageiro)
        final Set<Marker> currentMarkers = Set<Marker>.from(_markers);

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final data = snapshot.data!;
          final lat = data['latitude'];
          final lng = data['longitude'];

          if (lat is double && lng is double) {
            final driverPosition = LatLng(lat, lng);

            // Remove o marcador antigo do motorista e adiciona o novo
            currentMarkers
                .removeWhere((m) => m.markerId.value == _driverMarkerId);
            currentMarkers.add(
              Marker(
                markerId: const MarkerId(_driverMarkerId),
                position: driverPosition,
                infoWindow: const InfoWindow(title: 'Motorista'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
              ),
            );

            // Anima a câmera para a nova posição do motorista
            _mapController?.animateCamera(CameraUpdate.newLatLng(driverPosition));
          }
        }

        // Mostra um indicador de carregamento no início
        if (snapshot.connectionState == ConnectionState.waiting &&
            currentMarkers.length <= 1) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mostra um erro se o stream falhar
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro ao carregar a localização: ${snapshot.error}'));
        }

        // Retorna o mapa com o conjunto de marcadores atualizado
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialCameraPosition,
            zoom: 14.0,
          ),
          markers: currentMarkers,
          onMapCreated: _onMapCreated,
        );
      },
    );
  }

  /// Constrói o mapa para o MOTORISTA, que é atualizado via setState.
  Widget _buildDriverMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 14.0),
      markers: _markers,
      onMapCreated: _onMapCreated,
    );
  }
}
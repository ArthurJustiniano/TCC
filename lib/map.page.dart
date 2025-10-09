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
  final int trackedUserId; // Alterado para int para refletir IDs numéricos
  final bool isDriver;

  const MapPage({super.key, required this.trackedUserId, this.isDriver = false});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final LatLng _initialCameraPosition = const LatLng(-23.550520, -46.633308); // São Paulo

  // Ícones personalizados
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _personIcon;

  // Stream para o modo motorista
  StreamSubscription<Position>? _positionStreamSubscription;
  // Assinatura do stream para o modo passageiro
  StreamSubscription<List<Map<String, dynamic>>>? _passengerLocationSubscription;

  @override
  void initState() {
    super.initState();
    // Apenas solicita a permissão. A lógica do mapa começará em onMapCreated.
    _requestLocationPermission();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(16, 16)),
      'assets/images/marcador_onibus.png',
    );
    _personIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(16, 16)),
      'assets/images/marcador_pessoa.png',
    );
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setupMapAndModes(); // Ponto de entrada principal da lógica do mapa
  }

  /// Configura o mapa e inicia os modos motorista/passageiro.
  Future<void> _setupMapAndModes() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A permissão de localização é necessária para usar o mapa.')),
        );
      }
      return;
    }

    // Obtém a posição inicial do usuário para configurar o mapa
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final initialLatLng = LatLng(position.latitude, position.longitude);

      // Anima a câmera para a posição inicial para ambos os tipos de usuário
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(initialLatLng, 16.0));

      if (widget.isDriver) {
        // Adiciona o marcador do próprio motorista e começa a enviar atualizações
        _updateMarker(Marker(
          markerId: const MarkerId(_driverMarkerId),
          position: initialLatLng,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
        _startSendingDriverLocation();
      } else {
        // Adiciona o marcador do próprio passageiro e começa a ouvir o motorista
        _updateMarker(Marker(
          markerId: const MarkerId(_userMarkerId),
          position: initialLatLng,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon: _personIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
        _startListeningToDriverLocation();
      }
    } catch (e) {
      debugPrint("Erro ao obter localização inicial: $e");
    }
  }

  /// MODO MOTORISTA: Inicia o envio contínuo de localização.
  void _startSendingDriverLocation() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
      ),
    ).listen((Position position) async {
      final driverLocation = LatLng(position.latitude, position.longitude);
      _updateMarker(
        Marker(
          markerId: const MarkerId(_driverMarkerId),
          position: driverLocation,
          infoWindow: const InfoWindow(title: 'Sua Posição'),
          icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );

      try {
        await Supabase.instance.client.from('locations').upsert({
          'user_id': widget.trackedUserId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (error) {
        debugPrint('Erro ao enviar localização: $error');
      }
    });
  }

  /// MODO PASSAGEIRO: Começa a ouvir a localização do motorista via Supabase.
  void _startListeningToDriverLocation() {
    final stream = Supabase.instance.client
        .from('locations')
        .stream(primaryKey: ['id']).eq('user_id', widget.trackedUserId);

    _passengerLocationSubscription = stream.listen((listOfMaps) {
      debugPrint('PASSAGEIRO - Dados recebidos: $listOfMaps');
      if (listOfMaps.isNotEmpty) {
        final data = listOfMaps.first;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();

        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          final driverPosition = LatLng(lat, lng);
          final driverMarker = Marker(
            markerId: const MarkerId(_driverMarkerId),
            position: driverPosition,
            infoWindow: const InfoWindow(title: 'Motorista'),
            icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );
          _updateMarker(driverMarker);
          _mapController?.animateCamera(CameraUpdate.newLatLng(driverPosition));
        }
      }
    }, onError: (error) {
      debugPrint('PASSAGEIRO - Erro no stream: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao receber localização: $error')),
      );
    });
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
    _passengerLocationSubscription?.cancel();
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
      // O mapa agora é o corpo principal, e seus marcadores são atualizados via setState.
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 14.0),
        markers: _markers,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
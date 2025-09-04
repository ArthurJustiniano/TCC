import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final String? trackedUserId;

  const MapPage({super.key, this.trackedUserId});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  double lat = -20.834999;
  double long = -49.488359;
  LatLng? _trackedUserPosition;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _centerOnUserLocation();
    _fetchPontos();
    if (widget.trackedUserId != null) {
      _startTrackingMotorista(widget.trackedUserId!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'O serviço de localização está desabilitado. Por favor, ative-o.'),
        backgroundColor: Colors.red,
      ));
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && mounted) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A permissão de localização foi negada.'),
          backgroundColor: Colors.orange,
        ));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Permissão negada permanentemente. Abra as configurações para permitir.'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: openAppSettings,
          ),
        ),
      );
      return null;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Obtendo sua localização...'),
        backgroundColor: Colors.blue,
      ));
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _centerOnUserLocation() async {
    final Position? position = await _getCurrentLocation();
    if (position != null && mounted) {
      final userLocation = LatLng(position.latitude, position.longitude);

      _updateMarker(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            infoWindow: const InfoWindow(title: 'Sua Posição'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16.0));
    }
  }

  void _updateMarker(Marker marker) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId == marker.markerId);
      _markers.add(marker);
    });
  }

  void _centerOnTrackedUser() {
    if (_trackedUserPosition != null && mounted) {
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_trackedUserPosition!, 16.0));
    }
  }

  Future<void> _fetchPontos() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/pontos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _markers.clear();
          for (var ponto in data) {
            final marker = Marker(
              markerId: MarkerId(ponto['id_ponto'].toString()),
              position: LatLng(ponto['latitude'], ponto['longitude']),
              infoWindow: InfoWindow(title: ponto['descricao']),
            );
            _markers.add(marker);
          }
        });
      } else {
        print('Erro ao buscar pontos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar pontos: $e');
    }
  }

  void _startTrackingMotorista(String motoristaId) {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchMotoristaLocation(motoristaId);
    });
  }

  Future<void> _fetchMotoristaLocation(String motoristaId) async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/motorista/$motoristaId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      LatLng pos = LatLng(data['latitude'], data['longitude']);
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'motorista');
        _markers.add(Marker(
          markerId: MarkerId('motorista'),
          position: pos,
          infoWindow: InfoWindow(title: 'Motorista'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
        mapController.animateCamera(CameraUpdate.newLatLng(pos));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Localizações'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, long),
          zoom: 14.0,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}

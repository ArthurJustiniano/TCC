import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  double lat = -20.834999;
  double long = -49.488359;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// Obtem a localização atual do usuário
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
            onPressed: openAppSettings, // Abre as configurações do app
          ),
        ),
      );
      return null;
    }

    // Se chegou até aqui, as permissões foram concedidas.
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

  /// Centraliza a câmera na posição atual do usuário
  void _centerOnUserLocation() async {
    final Position? position = await _getCurrentLocation();
    if (position != null && mounted) {
      final userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            infoWindow: const InfoWindow(title: 'Sua Posição'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });

      mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa com Localização')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        myLocationEnabled: true, // Mostra o ponto azul no mapa
        myLocationButtonEnabled: false, // Botão padrão do Google Maps (opcional)
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, long),
          zoom: 15.0,
        ),
        markers: markers,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _centerOnUserLocation,
            tooltip: 'Minha Localização',
            child: const Icon(Icons.my_location),
            heroTag: 'userLocation',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                lat = -20.8394218;
                long = -49.4937192;
                final position = LatLng(lat, long);
                markers.add(
                  Marker(
                    markerId: MarkerId(position.toString()),
                    position: position,
                    infoWindow: const InfoWindow(title: 'Ônibus'),
                  ),
                );
                mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 18.0));
              });
            },
            tooltip: 'Localizar Ônibus',
            child: const Icon(Icons.directions_bus),
            heroTag: 'busLocation',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

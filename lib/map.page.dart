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

  void _updateLocation() {
    setState(() {
      lat = -20.8394218;
      long = -49.4937192;

      final position = LatLng(lat, long);
      markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: const InfoWindow(title: 'Nova Posição'),
        ),
      );
      mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 18.0));
    });
  }

  /// Função para obter a posição atual do usuário.
  /// Retorna um objeto Position ou null se a permissão for negada.
  Future<Position?> _getCurrentLocation() async {
    // 1. Verifica se o serviço de localização está habilitado no dispositivo
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // O serviço de localização está desabilitado.
      // Você pode mostrar um alerta para o usuário pedindo para habilitá-lo.
      print('Serviço de localização desabilitado.');
      return null;
    }

    // 2. Verifica o status da permissão
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // A permissão foi negada uma vez, solicita novamente.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // O usuário negou a permissão.
        print('Permissão de localização negada.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // O usuário negou a permissão permanentemente.
      // Você deve direcionar o usuário para as configurações do app.
      print('Permissão de localização negada permanentemente.');
      // Exemplo de como abrir as configurações do app:
      // await openAppSettings();
      return null;
    }

    // 3. Se a permissão foi concedida, obtém a localização
    print('Obtendo a localização atual...');
    return await Geolocator.getCurrentPosition();
  }

  void _centerOnUserLocation() async {
    final Position? position = await _getCurrentLocation();
    if (position != null && mounted) {
      final userLocation = LatLng(position.latitude, position.longitude);

      // Adiciona um marcador para a posição do usuário
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

      // Move a câmera para a posição do usuário
      mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Completo')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onCameraMove: (data) {
           print(data);
        },
        onTap: (position) {
          print(position);
        },
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
            heroTag: 'userLocation', // heroTag é necessário para múltiplos FABs
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _updateLocation,
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
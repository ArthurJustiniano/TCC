import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  late GoogleMapController mapController;
  double lat = -20.834999;
  double long = -49.488359;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Completo')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, long),
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId('marker1'),
            position: LatLng(lat, long),
            infoWindow: InfoWindow(title: 'Localização'),
          ),
        },
      ),
        
      
    );
  }
}
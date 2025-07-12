import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      // Alteração para incluir o zoom
      mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 18.0));
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: _updateLocation,
        child: const Icon(Icons.directions_bus),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
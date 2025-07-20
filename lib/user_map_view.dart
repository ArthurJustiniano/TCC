import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMapView extends StatefulWidget {
  final String userIdToTrack;

  const UserMapView({super.key, required this.userIdToTrack});

  @override
  State<UserMapView> createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _listenToLocationUpdates();
  }

  void _listenToLocationUpdates() {
    FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.userIdToTrack)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        final lat = data['latitude'];
        final lng = data['longitude'];

        if (lat != null && lng != null) {
          final position = LatLng(lat, lng);
          _updateMarker(position);
        }
      }
    });
  }

  void _updateMarker(LatLng position) async {
    setState(() {
      _userMarker = Marker(
        markerId: MarkerId(widget.userIdToTrack),
        position: position,
        infoWindow: const InfoWindow(title: 'Localização do Usuário'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });

    // Opcional: mover a câmera para a nova posição do marcador
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rastreando Usuário')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-23.550520, -46.633308), // Posição inicial (São Paulo)
          zoom: 14,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _userMarker != null ? {_userMarker!} : {},
      ),
    );
  }
}
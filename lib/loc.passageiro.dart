// Este código deve estar na tela do passageiro que exibe o mapa

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreenForPassenger extends StatefulWidget {
  final String driverId; // O ID do motorista que o passageiro está rastreando

  const MapScreenForPassenger({Key? key, required this.driverId}) : super(key: key);

  @override
  _MapScreenForPassengerState createState() => _MapScreenForPassengerState();
}

class _MapScreenForPassengerState extends State<MapScreenForPassenger> {
  // Stream que vai receber as atualizações de localização
  late final Stream<Map<String, dynamic>> _locationStream;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _setupLocationStream();
  }

  void _setupLocationStream() {
    // Escuta mudanças na tabela 'locations' APENAS para o motorista específico
    _locationStream = Supabase.instance.client
        .from('locations')
        .stream(primaryKey: ['user_id']).eq('user_id', widget.driverId)
        .map((listOfMaps) {
          // O stream retorna uma lista, pegamos o primeiro (e único) item
          if (listOfMaps.isNotEmpty) {
            return listOfMaps.first;
          }
          // Retorna um mapa vazio se não houver dados, para o StreamBuilder lidar com isso.
          return <String, dynamic>{};
        });
  }

  // Opcional: para animar a câmera para a nova posição do motorista
  void _animateCamera(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localização do Motorista')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _locationStream,
        builder: (context, snapshot) {
          Set<Marker> markers = {};

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!;
            final lat = data['latitude'];
            final lng = data['longitude'];

            if (lat is double && lng is double) {
              final driverPosition = LatLng(lat, lng);

              // Cria o marcador diretamente para esta reconstrução do widget
              markers = {
                Marker(
                  markerId: const MarkerId('driver_location'),
                  position: driverPosition,
                  infoWindow: const InfoWindow(title: 'Motorista'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                )
              };

              // Anima a câmera para a nova posição
              _animateCamera(driverPosition);
            }
          }
          
          // O GoogleMap é reconstruído pelo StreamBuilder com os marcadores atualizados.
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(-23.550520, -46.633308), // Posição inicial
              zoom: 15,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          );
        },
      ),
    );
  }
}

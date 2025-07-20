import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Simulação do ID do usuário logado. Idealmente, viria do Firebase Auth.
  final String userId; 

  LocationService({required this.userId});

  /// Inicia o envio de atualizações de localização para o Firestore.
  void startSendingLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros de deslocamento
      ),
    ).listen((Position position) {
      _updateUserLocation(position);
    });
  }

  /// Atualiza a localização do usuário no Firestore.
  Future<void> _updateUserLocation(Position position) async {
    try {
      await _firestore.collection('locations').doc(userId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(), // Usa o timestamp do servidor
      });
    } catch (e) {
      print('Erro ao atualizar a localização: $e');
    }
  }
}
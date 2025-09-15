// Este código deve estar na tela do motorista

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ... dentro do seu StatefulWidget ...

void _startSendingLocation() {
  // Pede permissão e começa a escutar as mudanças de posição
  Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualiza a cada 10 metros
    )
  ).listen((Position position) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      // Usa 'upsert' para criar ou atualizar a localização do motorista
      await Supabase.instance.client.from('locations').upsert({
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      // Tratar erro de envio
      print('Erro ao enviar localização: $error');
    }
  });
}

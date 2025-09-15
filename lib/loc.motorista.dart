// Este código deve estar na tela do motorista

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  _DriverMapScreenState createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  @override
  void initState() {
    super.initState();
    _initializeLocationSharing();
  }

  Future<void> _initializeLocationSharing() async {
    // 1. Solicita permissão de localização
    var status = await Permission.location.request();
    if (status.isGranted) {
      // 2. Se a permissão for concedida, inicia o envio
      _startSendingLocation();
    } else {
      // Opcional: Mostrar uma mensagem se a permissão for negada
      print('Permissão de localização negada.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A permissão de localização é necessária para usar esta função.')),
      );
    }
  }

  void _startSendingLocation() {
    // Começa a escutar as mudanças de posição
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
      ),
    ).listen((Position position) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // Não faz nada se o usuário não estiver logado

      try {
        // Usa 'upsert' para criar ou atualizar a localização do motorista
        await Supabase.instance.client.from('locations').upsert({
          'user_id': user.id,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('Localização enviada: ${position.latitude}, ${position.longitude}');
      } catch (error) {
        print('Erro ao enviar localização: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Você pode adicionar um mapa aqui também, ou apenas uma tela de status
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Motorista')),
      body: const Center(
        child: Text('Compartilhando sua localização em tempo real...'),
      ),
    );
  }
}

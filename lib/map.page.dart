import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// Boas práticas: Centralizar constantes da API e IDs dos marcadores.
// IMPORTANTE: Substitua '127.0.0.1' pelo IP do seu computador na rede
// (ex: '192.168.1.5') ou '10.0.2.2' se estiver usando um emulador Android.
const String _baseUrl = 'http://192.168.1.7:5000';
const String _userMarkerId = 'user_location';
const String _driverMarkerId = 'driver_location';

class MapPage extends StatefulWidget {
  final String? trackedUserId;
  final bool isDriver;

  const MapPage({super.key, this.trackedUserId, this.isDriver = false});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  // Posição inicial do mapa (ex: centro da cidade)
  final LatLng _initialCameraPosition = const LatLng(-20.834999, -49.488359);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _centerOnUserLocation();
    _fetchPontos();
    if (widget.trackedUserId != null) {
      if (widget.isDriver) {
        _startSendingLocation(widget.trackedUserId!);
      } else {
        _startTrackingMotorista(widget.trackedUserId!);
      }
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
            markerId: const MarkerId(_userMarkerId),
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

  Future<void> _fetchPontos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pontos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          // BUG FIX: Não limpa os marcadores para não remover o do usuário/motorista.
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
        debugPrint('Erro ao buscar pontos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar pontos: $e');
    }
  }

  /// Para o Passageiro: busca a localização do motorista do servidor.
  void _startTrackingMotorista(String motoristaId) {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      http.Response response;
      try {
        // 1. Tenta fazer a requisição de rede
        response = await http.get(Uri.parse('$_baseUrl/motorista/$motoristaId'));
      } catch (e) {
        // ERRO DE REDE: O app não conseguiu se conectar ao servidor (IP, Firewall, Wi-Fi)
        debugPrint('ERRO DE REDE ao buscar localização: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha de conexão com o servidor. Verifique o IP e o Firewall.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return; // Para a execução aqui
      }

      if (!mounted) return;

      // 2. Verifica se o servidor respondeu com sucesso
      if (response.statusCode == 200) {
        try {
          // 3. Tenta processar os dados recebidos
          final data = jsonDecode(response.body);
          final LatLng motoristaPosition = LatLng(data['latitude'], data['longitude']);

          _updateMarker(
            Marker(
              markerId: const MarkerId(_driverMarkerId),
              position: motoristaPosition,
              infoWindow: const InfoWindow(title: 'Localização do Motorista'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
          // MELHORIA: Centraliza a câmera no motorista para confirmar visualmente a recepção dos dados.
          mapController.animateCamera(CameraUpdate.newLatLng(motoristaPosition));
        } catch (e) {
          // ERRO DE DADOS: O app recebeu uma resposta, mas o formato é inválido.
          debugPrint('ERRO DE PARSING de dados: $e');
          debugPrint('DADOS RECEBIDOS: ${response.body}'); // Imprime o que o servidor enviou
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Dados recebidos do servidor são inválidos.')));
          }
        }
      } else {
        // ERRO DE SERVIDOR: O servidor respondeu, mas com um erro (404, 500, etc.)
        debugPrint('ERRO DE SERVIDOR: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Servidor respondeu com erro ${response.statusCode}.')),
          );
        }
      }
    });
  }

  /// Para o Motorista: envia a própria localização para o servidor.
  void _startSendingLocation(String myDriverId) {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final Position? position = await _getCurrentLocation();
      if (position != null) {
        // 1. Atualiza o marcador no próprio mapa do motorista
        final myLocation = LatLng(position.latitude, position.longitude);
        _updateMarker(
          Marker(
            markerId: const MarkerId(_driverMarkerId),
            position: myLocation,
            infoWindow: const InfoWindow(title: 'Sua Posição (Motorista)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        mapController.animateCamera(CameraUpdate.newLatLng(myLocation));

        // 2. Envia a localização para o servidor
        _postLocationToServer(position, myDriverId);
      }
    });
  }

  Future<void> _postLocationToServer(Position position, String driverId) async {
    final url = Uri.parse('$_baseUrl/motorista/$driverId/localizacao');
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        debugPrint('Localização enviada com sucesso.');
      } else {
        debugPrint('Erro ao enviar localização: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Falha ao sincronizar localização: ${response.statusCode}'),
            backgroundColor: Colors.orange[800],
          ));
        }
      }
    } catch (e) {
      debugPrint('Erro de rede ao enviar localização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sem conexão para enviar localização.'),
          backgroundColor: Colors.red,
        ));
      }
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
          target: _initialCameraPosition,
          zoom: 14.0,
        ),
        markers: _markers,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
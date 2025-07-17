// Importa a biblioteca 'dart:async' para usar funcionalidades assíncronas como Streams (StreamSubscription).
import 'dart:async';
// Importa o pacote principal do Flutter para construir a interface do usuário.
import 'package:flutter/material.dart';
// Importa o pacote do Google Maps para Flutter, para exibir mapas.
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Importa o pacote Geolocator para obter a localização GPS do dispositivo.
import 'package:geolocator/geolocator.dart';
// Importa o pacote Permission Handler para solicitar e verificar permissões do dispositivo (como localização).
import 'package:permission_handler/permission_handler.dart';
// Importa o pacote do Cloud Firestore para interagir com o banco de dados em tempo real do Firebase.
import 'package:cloud_firestore/cloud_firestore.dart';

// MapPage é um widget com estado (StatefulWidget) porque seu conteúdo (posição no mapa, marcadores) pode mudar.
class MapPage extends StatefulWidget {
  // Recebe o ID do USUÁRIO que deve ser rastreado.
  // Pode ser nulo se nenhum rastreamento específico for necessário.
  final String? trackedUserId;

  // Construtor do widget. 'key' é passado para a classe pai e 'driverId' é um parâmetro obrigatório ou opcional.
  const MapPage({super.key, this.trackedUserId});

  @override
  _MapPageState createState() => _MapPageState();
}

// _MapPageState contém o estado e a lógica para o widget MapPage.
class _MapPageState extends State<MapPage> {
  // Controlador para o widget do GoogleMap, permite interagir com o mapa (ex: mover a câmera).
  late GoogleMapController mapController;
  // Um conjunto (Set) de marcadores que serão exibidos no mapa. Usar um Set garante que não haja marcadores duplicados.
  final Set<Marker> _markers = {};
  // Latitude inicial padrão do mapa.
  double lat = -20.834999;
  // Longitude inicial padrão do mapa.
  double long = -49.488359;
  // Armazena a última posição conhecida do usuário rastreado (vindo do Firestore).
  LatLng? _trackedUserPosition;

  // Inscrição (Subscription) para o stream de dados do Firestore.
  // Permite "escutar" as atualizações de localização em tempo real.
  StreamSubscription<DocumentSnapshot>? _locationSubscription;

  // O método initState é chamado uma vez quando o widget é inserido na árvore de widgets.
  @override
  void initState() {
    super.initState();
    // Inicia o rastreamento da localização do motorista/usuário a partir do Firestore.
    _startTrackingFromFirestore();
    // Obtém a localização do usuário atual e centraliza o mapa nele.
    _centerOnUserLocation();
  }

  // Callback chamado quando o mapa é criado e está pronto para uso.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// Obtém a localização atual do usuário do dispositivo.
  Future<Position?> _getCurrentLocation() async {
    // Verifica se o serviço de localização (GPS) está ativado no dispositivo.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // Se não estiver ativado, exibe uma mensagem para o usuário.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'O serviço de localização está desabilitado. Por favor, ative-o.'),
        backgroundColor: Colors.red,
      ));
      return null; // Retorna nulo pois não é possível obter a localização.
    }

    // Verifica o status da permissão de localização para o aplicativo.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && mounted) {
      // Se a permissão foi negada, solicita a permissão ao usuário.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Se o usuário negar novamente, exibe uma mensagem.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A permissão de localização foi negada.'),
          backgroundColor: Colors.orange,
        ));
        return null;
      }
    }

    // Verifica se a permissão foi negada permanentemente.
    if (permission == LocationPermission.deniedForever && mounted) {
      // Se foi negada permanentemente, informa o usuário e oferece um atalho para as configurações do app.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Permissão negada permanentemente. Abra as configurações para permitir.'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: openAppSettings, // Função do pacote 'permission_handler' que abre as configurações.
          ),
        ),
      );
      return null;
    }

    // Se chegou até aqui, as permissões foram concedidas.
    if (mounted) {
      // Informa o usuário que a localização está sendo obtida.
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Obtendo sua localização...'),
        backgroundColor: Colors.blue,
      ));
    }
    
    // Retorna a posição atual com alta precisão.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Centraliza a câmera do mapa na posição atual do usuário.
  void _centerOnUserLocation() async {
    // Obtém a posição atual.
    final Position? position = await _getCurrentLocation();
    // Se a posição foi obtida com sucesso e o widget ainda está na tela ('mounted').
    if (position != null && mounted) {
      // Cria um objeto LatLng com as coordenadas da posição.
      final userLocation = LatLng(position.latitude, position.longitude);

      // Adiciona ou atualiza um marcador para a posição do usuário.
      _updateMarker(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLocation,
            infoWindow: const InfoWindow(title: 'Sua Posição'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Marcador verde.
          ),
        );
      // Anima a câmera do mapa para a nova localização do usuário com um nível de zoom de 16.
      mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16.0));
    }
  }

  // Função auxiliar para adicionar ou atualizar um marcador no mapa de forma segura.
  void _updateMarker(Marker marker) {
    // Verifica se o widget ainda está montado para evitar erros.
    if (!mounted) return;
    // Chama setState para reconstruir a UI com o marcador atualizado.
    setState(() {
      // Remove o marcador antigo (se existir) com o mesmo ID antes de adicionar o novo.
      _markers.removeWhere((m) => m.markerId == marker.markerId);
      // Adiciona o novo marcador ao conjunto de marcadores.
      _markers.add(marker);
    });
  }

  /// Centraliza a câmera na posição do usuário rastreado (o ônibus).
  void _centerOnTrackedUser() {
    // Verifica se existe uma posição rastreada e se o widget está montado.
    if (_trackedUserPosition != null && mounted) {
      // Anima a câmera para a posição do usuário rastreado.
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_trackedUserPosition!, 16.0));
    }
  }

  /// Inicia o monitoramento da localização de um documento no Firestore.
  void _startTrackingFromFirestore() {
    // Se não foi fornecido um ID de usuário para rastrear, não faz nada.
    if (widget.trackedUserId == null) return;

    // Cancela qualquer "escuta" (subscription) anterior para evitar múltiplos listeners e vazamentos de memória.
    _locationSubscription?.cancel();

    // Cria uma referência ao documento do usuário na coleção 'user_locations'.
    // Exemplo: 'user_locations/davi_silva'
    final userDocRef = FirebaseFirestore.instance
        .collection('user_locations')
        .doc(widget.trackedUserId);

    // "Escuta" (listen) as mudanças no documento em tempo real usando snapshots.
    _locationSubscription =
        userDocRef.snapshots().listen((DocumentSnapshot doc) {
      // Callback executado sempre que o documento muda.
      if (doc.exists && doc.data() != null) {
        // Se o documento existe e tem dados, extrai as informações.
        final data = doc.data() as Map<String, dynamic>;

        // VERIFICAÇÃO DE SEGURANÇA: Garante que os campos existem e são do tipo double.
        if (data.containsKey('latitude') &&
            data.containsKey('longitude') &&
            data['latitude'] is double &&
            data['longitude'] is double) {
          final userPosition = LatLng(data['latitude'], data['longitude']);

          // Guarda a posição na variável de estado para uso posterior (ex: botão de centralizar).
          if (mounted) {
            setState(() {
              _trackedUserPosition = userPosition;
            });
          }

          // Tenta obter o nome do usuário do documento, se não existir, usa o ID.
          final trackedUserName = data['nome'] as String? ?? widget.trackedUserId;

          // Atualiza o marcador do usuário rastreado no mapa com a nova posição.
          _updateMarker(
            Marker(
              markerId: const MarkerId('tracked_user_location'),
              position: userPosition,
              infoWindow: InfoWindow(
                  title: trackedUserName ??
                      'Usuário rastreado'), // O título do marcador será o nome do usuário.
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
                  .hueOrange), // Marcador LARANJA para o outro usuário.
            ),
          );
        }
      }
    }, onError: (error) {
      // Callback para lidar com erros durante a escuta.
      print("Erro ao escutar localização: $error");
    });
  }

  // O método dispose é chamado quando o widget é removido permanentemente da árvore de widgets.
  @override
  void dispose() {
    // É MUITO IMPORTANTE cancelar a inscrição (subscription) do Firestore ao sair da tela
    // para liberar recursos e evitar vazamentos de memória (memory leaks).
    _locationSubscription?.cancel();
    super.dispose();
  }

  // Constrói a interface do usuário do widget.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra no topo da tela (AppBar).
      appBar: AppBar(title: Text(widget.trackedUserId != null
          ? 'Localização de ${widget.trackedUserId}'
          : 'Mapa')),
      // O corpo da tela será o mapa do Google.
      body: GoogleMap(
        // Callback para quando o mapa for criado.
        onMapCreated: _onMapCreated,
        // Mostra o ponto azul da localização atual do usuário no mapa.
        myLocationEnabled: true,
        // Oculta o botão padrão de "minha localização" do Google Maps, pois criamos um próprio.
        myLocationButtonEnabled: false,
        // Define a posição inicial da câmera do mapa.
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, long), // Posição alvo inicial.
          zoom: 15.0,
        ),
        // O conjunto de marcadores a serem exibidos no mapa.
        markers: _markers,
      ),
      // Botões de Ação Flutuantes (Floating Action Buttons).
      floatingActionButton: Column(
        // Alinha os botões na parte inferior.
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botão para centralizar na localização do próprio usuário.
          FloatingActionButton(
            onPressed: _centerOnUserLocation,
            tooltip: 'Minha Localização',
            child: const Icon(Icons.my_location),
            // 'heroTag' é necessário para evitar conflito quando há múltiplos FABs na mesma tela.
            heroTag: 'userLocation',
          ),
          // Espaçamento vertical entre os botões.
          const SizedBox(height: 16),
          // Botão para centralizar na rota (usuário rastreado).
          FloatingActionButton(
            onPressed: _centerOnTrackedUser,
            tooltip: 'Localizar Usuário',
            child: const Icon(Icons.person_pin_circle), // Ícone mais apropriado
            heroTag: 'trackedUserLocation',
          ),
        ],
      ),
      // Define a localização dos botões flutuantes.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

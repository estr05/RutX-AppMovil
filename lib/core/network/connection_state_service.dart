import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

enum RutxConnectionState { connected, connecting, offline }

class ConnectionStateService {
  static final ConnectionStateService _instance =
      ConnectionStateService._internal();
  factory ConnectionStateService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<RutxConnectionState> _stateController =
      StreamController<RutxConnectionState>.broadcast();
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicTimer;

  RutxConnectionState _currentState = RutxConnectionState.offline;
  bool _started = false;

  ConnectionStateService._internal();

  Stream<RutxConnectionState> get connectionStream => _stateController.stream;
  RutxConnectionState get currentState => _currentState;
  bool get isStarted => _started;
  bool get isOffline =>
      _started && _currentState == RutxConnectionState.offline;

  @visibleForTesting
  void setMockState(RutxConnectionState state) {
    _started = true;
    _currentState = state;
  }

  void start() {
    if (_started) return;
    _started = true;
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _checkActualConnection();
      } else {
        _updateState(RutxConnectionState.offline);
      }
    });

    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkActualConnection();
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        await _checkActualConnection();
      } else {
        _updateState(RutxConnectionState.offline);
      }
    } catch (e) {
      _updateState(RutxConnectionState.offline);
    }
  }

  Future<void> forceCheck() async {
    await _checkActualConnection();
  }

  Future<void> _checkActualConnection() async {
    _updateState(RutxConnectionState.connecting);

    // Producción (Cloudflare Tunnel): los sockets TCP crudos no validan el
    // borde — cloudflared acepta la conexión aunque el origen esté caído.
    // Se consulta /health con un Dio ligero, sin interceptores ni fallback.
    if (ApiConstants.isProductionEndpoint) {
      await _probeHealthProduccion();
      return;
    }

    try {
      final List<String> allUrls = [
        ApiConstants.empresaUrl,
        ApiConstants.tailscaleCasaUrl,
      ];

      bool hasConnection = false;

      // Intentar conectar con el socket a cualquiera de las IPs conocidas del servidor
      for (final url in allUrls) {
        try {
          final uri = Uri.parse(url);
          final socket = await Socket.connect(
            uri.host,
            uri.port,
            timeout: const Duration(seconds: 2),
          );
          socket.destroy();
          hasConnection = true;
          break; // Conectó a uno, el servidor está disponible
        } catch (_) {
          continue;
        }
      }

      if (hasConnection) {
        _updateState(RutxConnectionState.connected);
      } else {
        _updateState(RutxConnectionState.offline);
      }
    } catch (_) {
      _updateState(RutxConnectionState.offline);
    }
  }

  /// Sondeo ligero contra /health cuando la app apunta al túnel público.
  ///
  /// Usa una instancia propia de Dio (sin interceptores ni fallback) con
  /// timeouts cortos: cualquier fallo (DNS, TLS, edge u origen caído) se
  /// interpreta como servidor no disponible, nunca como sesión inválida.
  Future<void> _probeHealthProduccion() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final respuesta = await dio.get<dynamic>(
        '${ApiConstants.baseUrl}/health',
      );
      _updateState(
        respuesta.statusCode == 200
            ? RutxConnectionState.connected
            : RutxConnectionState.offline,
      );
    } catch (_) {
      _updateState(RutxConnectionState.offline);
    }
  }

  void _updateState(RutxConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(_currentState);
    }
  }

  void stop() {
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}

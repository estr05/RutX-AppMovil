import 'dart:async';
import 'connection_state_service.dart';
import 'sync_queue_processor.dart';
import '../../features/sales/data/sales_repository.dart';
import '../../features/cobranza/data/cobranza_repository.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  final ConnectionStateService _connectionState = ConnectionStateService();
  final SyncQueueProcessor _processor = SyncQueueProcessor();
  StreamSubscription<RutxConnectionState>? _subscription;

  void start() {
    _processor.registerHandler('venta', (entidadId) async {
      return await SalesRepository().uploadOne(entidadId);
    });
    _processor.registerHandler('cobranza', (entidadId) async {
      return await CobranzaRepository().uploadOne(entidadId);
    });

    _subscription?.cancel();
    _subscription = _connectionState.connectionStream.listen((state) {
      if (state == RutxConnectionState.connected) {
        _processor.processQueue();
      }
    });
    _syncIfConnected();
  }

  void _syncIfConnected() {
    if (_connectionState.currentState == RutxConnectionState.connected) {
      _processor.processQueue();
    }
  }

  Future<int> syncNow() async {
    return await _processor.processQueue();
  }

  SyncQueueProcessor get processor => _processor;

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

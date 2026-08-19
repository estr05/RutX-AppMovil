import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../storage/local_storage.dart';

class NotificationPollingService with WidgetsBindingObserver {
  static final NotificationPollingService _instance =
      NotificationPollingService._();
  factory NotificationPollingService() => _instance;
  NotificationPollingService._();

  final NotificationRepository _repository = NotificationRepository();
  final LocalStorage _storage = LocalStorage();
  Timer? _timer;
  final _controller = StreamController<int>.broadcast();
  int _lastCount = 0;
  bool _paused = false;

  Stream<int> get countStream => _controller.stream;
  int get lastCount => _lastCount;

  void start({Duration interval = const Duration(seconds: 180)}) {
    stop();
    WidgetsBinding.instance.addObserver(this);
    _poll();
    _timer = Timer.periodic(interval, (_) {
      if (!_paused) _poll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
  }

  Future<void> _poll() async {
    try {
      final vendedorId = await _storage.getVendedorId();
      if (vendedorId == null) return;

      await _repository.fetchAndPersist(vendedorId);
      final after = await _repository.getUnreadCount();

      if (after != _lastCount) {
        _lastCount = after;
        _controller.add(after);
      }
    } catch (e, st) {
      debugPrint('[NotificationPolling] Error en polling: $e\n$st');
    }
  }

  /// Dispara una verificacion inmediata de notificaciones y emite el nuevo
  /// conteo a [countStream] si cambio. Se usa despues de marcar leidas para
  /// que los badges de todos los AppBars se actualicen al instante.
  Future<void> refresh() async {
    await _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

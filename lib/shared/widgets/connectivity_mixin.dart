import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/network/connection_state_service.dart';

mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  final ConnectionStateService _connectionService = ConnectionStateService();
  StreamSubscription<RutxConnectionState>? _connectivitySub;
  RutxConnectionState connectionState = RutxConnectionState.offline;

  bool get isConnected => connectionState == RutxConnectionState.connected;

  void setupConnectivity() {
    _connectivitySub = _connectionService.connectionStream.listen((state) {
      if (mounted) setState(() => connectionState = state);
    });
    connectionState = _connectionService.currentState;
  }

  void disposeConnectivity() {
    _connectivitySub?.cancel();
  }
}

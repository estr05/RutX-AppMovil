import 'package:flutter/material.dart';
import '../../core/network/connection_state_service.dart';
import '../../core/theme/app_theme.dart';

class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({Key? key}) : super(key: key);

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  late final ConnectionStateService _connectionService;

  @override
  void initState() {
    super.initState();
    _connectionService = ConnectionStateService();
    // Start listening if not already started
    _connectionService.start();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RutxConnectionState>(
      stream: _connectionService.connectionStream,
      initialData: _connectionService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? RutxConnectionState.offline;

        Color indicatorColor;
        String labelText;

        switch (state) {
          case RutxConnectionState.connected:
            indicatorColor = AppTheme.statusGreen;
            labelText = 'Conectado';
            break;
          case RutxConnectionState.connecting:
            indicatorColor = AppTheme.statusAmber; // Yellow-ish
            labelText = 'Conectando...';
            break;
          case RutxConnectionState.offline:
            indicatorColor = AppTheme.statusOrange;
            labelText = 'Offline';
            break;
        }

        Widget indicator = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labelText,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        if (state == RutxConnectionState.offline) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _connectionService.forceCheck();
            },
            child: indicator,
          );
        }

        return indicator;
      },
    );
  }
}

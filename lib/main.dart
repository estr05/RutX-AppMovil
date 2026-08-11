import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/network/sync_service.dart';
import 'core/network/notification_polling_service.dart';
import 'core/network/connection_state_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      return true;
    };

    await AppDatabase().initialize();

    ConnectionStateService().start();
    SyncService().start();
    NotificationPollingService().start();

    runApp(const RutxApp());
  }, (error, stackTrace) {
    // Zone error captured
  });
}

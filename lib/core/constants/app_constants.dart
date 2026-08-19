class AppConstants {
  static const String appName = 'RUTX';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String vendedorIdKey = 'vendedor_id';
  static const String vendedorNombreKey = 'vendedor_nombre';
  static const String lastSyncKey = 'last_sync';

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Cache
  static const int maxCacheSize = 50 * 1024 * 1024;
}

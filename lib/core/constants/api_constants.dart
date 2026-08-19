import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Puerto del sincronizador
  static const int port = 5047;

  /// IP del PC en la red WiFi local
  static const String _empresaIp = '192.168.100.61';

  /// IP de Tailscale del PC donde corre el sincronizador
  static const String _tailscaleCasaIp = '100.71.116.89';

  static String get scheme => kReleaseMode ? 'https' : 'http';

  /// URL para red local
  static String get empresaUrl => '$scheme://$_empresaIp:$port';

  /// URL por Tailscale (cualquier red con VPN activa)
  static String get tailscaleCasaUrl => '$scheme://$_tailscaleCasaIp:$port';

  /// URL por defecto: Tailscale (donde corre el sincronizador).
  /// Si no responde, DioClient intenta la LAN local y
  /// memoriza la primera que funcione.
  static String get baseUrl => tailscaleCasaUrl;
}

// ============================================================================
// PRODUCCION (Cloudflare Tunnel) - FEATURE FLAG COMENTADO
// ----------------------------------------------------------------------------
// Pendiente de investigación de Cloudflare Tunnel. Cuando se active, el
// sincronizador se expone via `cloudflared` con un hostname público fijo
// y HTTPS, por ejemplo: https://sync.rutx.com
//
// PARA ACTIVAR:
//   1. Instalar/ejecutar cloudflared en la PC del sincronizador y crear el
//      tunnel apuntando a http://localhost:5047
//   2. En este archivo, descomentar el bloque PRODUCCION y comentar la
//      URL por defecto de abajo.
//   3. Compilar el APK de producción:
//        flutter build apk --dart-define=API_BASE_URL=https://sync.rutx.com
//
// CONFIGURACION DE cloudflared (config.yml de ejemplo):
//   tunnel: <TU_TUNNEL_ID>
//   credentials-file: C:\Users\<user>\.cloudflared\<TU_TUNNEL_ID>.json
//   ingress:
//     - hostname: sync.rutx.com
//       service: http://localhost:5047
//     - service: http_status:404
// ============================================================================
// class ApiConstants {
//   /// URL pública del sincronizador vía Cloudflare Tunnel (producción).
//   /// Se define en tiempo de compilación con --dart-define.
//   static const String baseUrl = String.fromEnvironment(
//     'API_BASE_URL',
//     defaultValue: 'https://sync.rutx.com',
//   );
// }
// ============================================================================
// // Nota: si se desea soportar fallback (producción -> Tailscale -> LAN),
// // conservar los bloques anteriores y hacer que baseUrl lea primero el
// // dart-define. Ejemplo con fallback por orden de preferencia:
// static String get baseUrl {
//   const String fromEnv = String.fromEnvironment('API_BASE_URL');
//   if (fromEnv.isNotEmpty) return fromEnv;
//   return tailscaleCasaUrl; // o empresaUrl como respaldo
// }
// ============================================================================

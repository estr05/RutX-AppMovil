

/// Constantes de conexión al Sincronizador.
///
/// DOS MODOS EXCLUYENTES, decididos en TIEMPO DE COMPILACIÓN:
///  - Sin `--dart-define=API_BASE_URL` => desarrollo: HTTP directo por
///    LAN/Tailscale al :5047 (comportamiento histórico intacto).
///  - Con `--dart-define=API_BASE_URL=https://sync.<cliente>.com`
///    => producción vía Cloudflare Tunnel: HTTPS obligatorio y ÚNICA URL,
///       sin fallback a IPs privadas (ver DioClient.fallbackCandidates y
///       ConnectionStateService._probeHealthProduccion).
class ApiConstants {
  ApiConstants._();

  /// Puerto del sincronizador en modo desarrollo.
  ///
  /// En producción cloudflared apunta al listener loopback :5048 del
  /// sincronizador; la app nunca conoce ese puerto: solo ve el hostname
  /// público HTTPS resuelto por Cloudflare.
  static const int port = 5047;

  /// IP del PC en la red WiFi local (modo desarrollo).
  static const String _empresaIp = '192.168.1.68';

  /// IP de Tailscale del PC donde corre el sincronizador (modo desarrollo).
  static const String _tailscaleCasaIp = '100.71.116.89';

  static String get scheme => 'http';

  /// Valor inyectado en compilación (--dart-define=API_BASE_URL=...).
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// true si esta APK fue compilada para el túnel público (producción).
  static bool get isProductionEndpoint => _envBaseUrl.trim().isNotEmpty;

  /// URL para red local (modo desarrollo)
  static String get empresaUrl => '$scheme://$_empresaIp:$port';

  /// URL por Tailscale, cualquier red con VPN activa (modo desarrollo)
  static String get tailscaleCasaUrl => '$scheme://$_tailscaleCasaIp:$port';

  /// Resuelve la URL base efectiva a partir del valor compilado.
  ///
  /// - Vacío/ausente: comportamiento histórico (Tailscale por defecto;
  ///   DioClient puede memorizar la LAN si Tailscale no responde).
  /// - Con valor: debe iniciar con `https://` — el túnel es el único punto
  ///   TLS; se recorta cualquier `/` final.
  ///
  /// Lanza [ArgumentError] si se compila con un valor que no sea HTTPS:
  /// mejor fallar al arrancar que enviar credenciales JWT en claro.
  @visibleForTesting
  static String resolveBaseUrl(String envUrl) {
    final url = envUrl.trim();
    if (url.isEmpty) {
      // Modo desarrollo: Tailscale primero; el fallback de DioClient
      // prueba la LAN local y memoriza la que funcione.
      return tailscaleCasaUrl;
    }
    final normalizada =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    if (!normalizada.toLowerCase().startsWith('https://')) {
      throw ArgumentError.value(
        url,
        'API_BASE_URL',
        'En producción la API solo se consume por HTTPS (Cloudflare Tunnel)',
      );
    }
    return normalizada;
  }

  /// URL base efectiva de esta compilación.
  static String get baseUrl => resolveBaseUrl(_envBaseUrl);
}

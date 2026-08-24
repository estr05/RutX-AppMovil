import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';
import '../../app/app.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/widgets/feedback_utils.dart';
import '../errors/app_error.dart';

class DioClient {
  static final DioClient _instance = DioClient._();
  factory DioClient() => _instance;
  DioClient._();

  final LocalStorage _storage = LocalStorage();
  Dio? _dio;

  static bool _isCerrandoSesion = false;

  void resetearSesion() {
    _isCerrandoSesion = false;
  }

  Dio get dio {
    if (_dio == null) {
      _dio = Dio(_createOptions());
      _dio!.interceptors.add(_authInterceptor());
      _dio!.interceptors.add(_fallbackInterceptor());
    }
    return _dio!;
  }

  BaseOptions _createOptions() => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(
      seconds: 30,
    ), // Firebird puede tardar con catálogos grandes
    headers: {'Content-Type': 'application/json'},
  );

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  /// Candidatos de respaldo SOLO para modo desarrollo (LAN/Tailscale).
  ///
  /// En producción (compilada con API_BASE_URL https) devuelve vacío:
  /// el túnel es la única ruta; JAMÁS se reintenta contra IPs privadas.
  @visibleForTesting
  static List<String> fallbackCandidates({
    bool esProduccion = false,
    String? urlFallada,
  }) {
    if (esProduccion || (urlFallada?.startsWith('https') ?? false)) {
      return const <String>[];
    }
    return <String>[
      ApiConstants.empresaUrl,
      ApiConstants.tailscaleCasaUrl,
    ].where((url) => url != urlFallada).toList();
  }

  InterceptorsWrapper _fallbackInterceptor() => InterceptorsWrapper(
    onError: (DioException error, ErrorInterceptorHandler handler) async {
      // Producción (Cloudflare Tunnel): sin fallback. El error se propaga
      // tal cual para que la UI refleje el estado de conexión real.
      if (ApiConstants.isProductionEndpoint ||
          error.requestOptions.baseUrl.startsWith('https')) {
        return handler.next(error);
      }

      if (_isNetworkError(error)) {
        // Candidatos ya sin la URL que acaba de fallar (y vacíos en producción)
        final List<String> urlsToTry = fallbackCandidates(
          urlFallada: error.requestOptions.baseUrl,
        );

        for (int i = 0; i < urlsToTry.length; i++) {
          String nextUrl = urlsToTry[i];

          try {
            final cloneDio = Dio(_createOptions());
            cloneDio.options.baseUrl = nextUrl;

            final token = await _storage.getToken();
            final headers = Map<String, dynamic>.from(
              error.requestOptions.headers,
            );
            if (token != null && token.isNotEmpty) {
              headers['Authorization'] = 'Bearer $token';
            }

            final options = Options(
              method: error.requestOptions.method,
              headers: headers,
            );

            final response = await cloneDio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: options,
            );

            // Si tuvo éxito, actualizamos la base URL principal para futuras peticiones
            _dio!.options.baseUrl = nextUrl;
            return handler.resolve(response);
          } on DioException catch (e) {
            // Si falla y es el último intento o no es error de red, pasamos el error final
            if (!_isNetworkError(e) || i == urlsToTry.length - 1) {
              return handler.next(e);
            }
            // Si no, continuamos el ciclo con la siguiente IP
          }
        }
      }
      return handler.next(error);
    },
  );

  InterceptorsWrapper _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Token expirado o inválido
        await cerrarSesionPorCaducidad();
      }
      handler.next(error);
    },
  );

  /// Limpia la sesión local y regresa al login cuando el servidor rechaza
  /// el token (401: expirado o inválido).
  ///
  /// Se usa tanto en el interceptor de auth como en el flujo de
  /// sincronización de ventas, para que un 401 durante un sync forzado
  /// también deje claro que hay que volver a iniciar sesión.
  Future<void> cerrarSesionPorCaducidad() async {
    if (_isCerrandoSesion) return;
    _isCerrandoSesion = true;

    await _storage.clearSession();

    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;

    if (context != null && context.mounted) {
      showError(
        context,
        AppError(
          mensajeUsuario:
              'Tu sesión ha caducado. Por favor, inicia sesión de nuevo.',
          esRecuperable: true,
        ),
      );
    }

    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

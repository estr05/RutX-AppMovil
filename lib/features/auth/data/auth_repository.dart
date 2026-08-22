import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/connection_state_service.dart';
import '../../../core/errors/app_error.dart';

class AuthRepository {
  final Dio _dio = DioClient().dio;
  final LocalStorage _localStorage = LocalStorage();

  Future<AppError?> login(String username, String password) async {
    if (ConnectionStateService().currentState == RutxConnectionState.offline) {
      return AppError(
        mensajeUsuario:
            'Sin conexion al servidor. Conectate e intenta de nuevo.',
        esRecuperable: true,
      );
    }
    DioClient().resetearSesion();
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'usuario': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'] as String;
        final vendedorId = response.data['vendedor_id'] as int? ?? 0;
        final vendedorNombre =
            response.data['vendedor_nombre'] as String? ?? '';
        final usuario = response.data['usuario'] as String? ?? username;
        final cajeroId = response.data['cajero_id'] as int? ?? 0;
        final cajaId = response.data['caja_id'] as int? ?? 0;
        final almacenId = response.data['almacen_id'] as int? ?? 0;
        final sucursalId = response.data['sucursal_id'] as int? ?? 0;

        await _localStorage.saveToken(token);
        await _localStorage.saveIdentidad(
          vendedorId: vendedorId,
          vendedorNombre: vendedorNombre,
          usuario: usuario,
          cajeroId: cajeroId,
          cajaId: cajaId,
          almacenId: almacenId,
          sucursalId: sucursalId,
        );
        return null;
      }
      return AppError(
        mensajeUsuario: 'Credenciales incorrectas.',
        esRecuperable: false,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AppError(
          mensajeUsuario: 'El servidor no responde. Verifica tu conexión.',
          esRecuperable: true,
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        return AppError(
          mensajeUsuario:
              'Sin conexión al servidor. Asegúrate de que el Sincronizador esté encendido.',
          esRecuperable: true,
        );
      }
      if (e.response?.statusCode == 401) {
        return AppError(
          mensajeUsuario: 'Usuario o contraseña incorrectos.',
          esRecuperable: false,
        );
      }
      if (e.response?.statusCode == 403) {
        final detalle =
            e.response?.data is Map
                ? (e.response!.data['mensaje'] as String? ?? '')
                : '';
        return AppError(
          mensajeUsuario:
              detalle.isNotEmpty
                  ? detalle
                  : 'Tu usuario no tiene permisos de vendedor en ruta.',
          esRecuperable: false,
        );
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        return AppError(
          mensajeUsuario: 'El servidor está temporalmente fuera de servicio.',
          esRecuperable: true,
        );
      }
      return AppError(
        mensajeUsuario: 'Error al iniciar sesión. Intenta de nuevo.',
        esRecuperable: true,
      );
    } catch (_) {
      return AppError(
        mensajeUsuario: 'Error inesperado. Intenta de nuevo.',
        esRecuperable: true,
      );
    }
  }

  /// Obtiene los datos actualizados del vendedor desde el backend
  /// usando el token JWT almacenado. Requiere tener un token valido.
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final hasToken = await hasValidToken();
      if (!hasToken) return null;

      final response = await _dio.get('/api/auth/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final vendedorId = data['vendedor_id'] as int? ?? 0;
        if (vendedorId > 0) {
          await _localStorage.saveIdentidad(
            vendedorId: vendedorId,
            vendedorNombre: data['vendedor_nombre'] as String? ?? '',
            usuario: data['usuario'] as String? ?? '',
            cajeroId: data['cajero_id'] as int? ?? 0,
            cajaId: data['caja_id'] as int? ?? 0,
            almacenId: data['almacen_id'] as int? ?? 0,
            sucursalId: data['sucursal_id'] as int? ?? 0,
          );
        }
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasValidToken() async {
    final token = await _localStorage.getToken();
    if (token == null || token.isEmpty) return false;
    return !_isJwtExpired(token);
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      return DateTime.now().isAfter(
        DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (_) {
      return true;
    }
  }

  Future<int?> getVendedorId() async {
    return await _localStorage.getVendedorId();
  }
}

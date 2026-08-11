import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/connection_state_service.dart';

class SummaryRepository {
  final Dio _dio = DioClient().dio;

  bool get _isOffline =>
      ConnectionStateService().currentState == RutxConnectionState.offline;

  /// Obtiene el resumen diario desde el endpoint de rutas:
  /// GET /api/v1/routes/summary?fecha={fecha}
  /// La identidad (usuario/caja/cajero) viaja en el token JWT, no en la URL.
  Future<Map<String, dynamic>?> getDailySummary(DateTime fecha) async {
    if (_isOffline) return null;
    try {
      final fechaStr =
          '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final response = await _dio.get(
        '/api/v1/routes/summary',
        queryParameters: {
          'fecha': fechaStr,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['resumen'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error al obtener resumen diario: $e');
      return null;
    }
  }

  /// Envia el cierre de ruta al endpoint:
  /// POST /api/v1/routes/close
  /// Valida las ventas realizadas vs lo reportado y calcula diferencias.
  /// La identidad (usuario/caja/cajero) viaja en el token JWT, no en el cuerpo.
  Future<Map<String, dynamic>> sendClosingData({
    required DateTime fecha,
    List<VentaPendiente> ventas = const [],
    double totalEfectivo = 0.0,
    double totalTarjeta = 0.0,
    double totalCredito = 0.0,
    double combustibleGastado = 0.0,
    double kilometrosRecorridos = 0.0,
    String? observaciones,
  }) async {
    if (_isOffline) {
      return {'mensaje': 'Sin conexion. El cierre se guardara localmente y se enviara al recuperar conexion.', 'hay_diferencia': false};
    }
    try {
      final response = await _dio.post(
        '/api/v1/routes/close',
        data: {
          'fecha': fecha.toIso8601String().substring(0, 10),
          'ventas_realizadas':
              ventas.where((v) => v.doctoPvId != null).map((v) => v.doctoPvId!).toList(),
          'total_efectivo': totalEfectivo,
          'total_tarjeta': totalTarjeta,
          'total_credito': totalCredito,
          'combustible_gastado': combustibleGastado,
          'kilometros_recorridos': kilometrosRecorridos,
          'observaciones': observaciones,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {
        'mensaje': 'Error en cierre de ruta',
        'hay_diferencia': true,
      };
    } catch (e) {
      print('Error en cierre de ruta: $e');
      return {
        'mensaje': 'Error en cierre de ruta: $e',
        'hay_diferencia': true,
      };
    }
  }

  /// Obtiene el resumen local del dia desde SQLite
  Future<Map<String, dynamic>> getLocalSummary(String fecha) async {
    final db = AppDatabase();
    await db.initialize();
    return await db.ventaDao.getResumenDelDia(fecha);
  }
}

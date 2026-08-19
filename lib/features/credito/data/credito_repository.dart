import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/connection_state_service.dart';
import '../../../core/database/app_database.dart';

class CreditoRepository {
  final Dio _dio;

  CreditoRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  bool get _isOffline =>
      ConnectionStateService().currentState == RutxConnectionState.offline;

  static List<Map<String, dynamic>>? _cache;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(seconds: 30);

  static void clearCache() {
    _cache = null;
    _cacheTimestamp = null;
  }

  Future<List<Map<String, dynamic>>> getPedidosCredito({
    int? clienteId,
    int? vendedorId,
    bool forceRefresh = false,
  }) async {
    final cacheValid =
        !forceRefresh &&
        _cache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

    if (cacheValid) {
      return _cache!;
    }

    // Si no hay conexion, usar cache o datos locales inmediatamente
    if (_isOffline) {
      if (_cache != null) return _cache!;
      return _getCreditosLocales();
    }

    try {
      final queryParams = <String, dynamic>{};
      if (clienteId != null) queryParams['cliente_id'] = clienteId;
      if (vendedorId != null) queryParams['vendedor_id'] = vendedorId;
      final response = await _dio.get(
        '/api/v1/credito/pedidos',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final creditos = data['creditos'] as List<dynamic>? ?? [];
        final result = creditos.cast<Map<String, dynamic>>();
        _cache = result;
        _cacheTimestamp = DateTime.now();
        return result;
      }
      return [];
    } catch (e) {
      // Si falla la red, usar cache o datos locales
      if (_cache != null) {
        return _cache!;
      }
      return _getCreditosLocales();
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentosCliente(int clienteId) async {
    if (_isOffline) return [];

    try {
      final response = await _dio.get(
        '/api/v1/credito/clientes/$clienteId/documentos',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final docs = data['documentos'] as List<dynamic>? ?? [];
        return docs.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCreditosLocales() async {
    try {
      final db = AppDatabase();
      await db.initialize();
      final clientes = await db.clienteDao.getAll();
      final creditos =
          clientes
              .where((c) => c.tipoVenta > 1 && c.saldo > 0)
              .map(
                (c) => {
                  'cliente_id': c.clienteId,
                  'nombre': c.nombreCliente,
                  'limite_credito': c.limiteCredito,
                  'saldo_pendiente': c.saldo,
                  'porcentaje_usado':
                      c.limiteCredito > 0
                          ? (c.saldo / c.limiteCredito) * 100
                          : 0.0,
                  'documentos_pendientes': 0,
                  'dias_atraso': 0,
                },
              )
              .toList();
      return creditos;
    } catch (_) {
      return [];
    }
  }
}

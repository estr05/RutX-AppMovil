import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/entities/cobranza_pendiente_entity.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/connection_state_service.dart';
import '../../../core/network/sync_queue_processor.dart';

class CobranzaRepository {
  final Dio _dio;

  CobranzaRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  bool get _isOffline =>
      ConnectionStateService().currentState == RutxConnectionState.offline;

  Future<Map<String, dynamic>> insertCobranza(CobranzaPendiente cobranza) async {
    await _saveLocally(cobranza);
    final queue = SyncQueueProcessor();
    await queue.enqueue('cobranza', cobranza.cobranzaMovilId);
    if (_isOffline) return {'error': true, 'message': 'Guardado local. Pendiente de sincronizacion.'};
    final result = await _syncOne(cobranza);
    if (result['error'] != true) {
      await queue.markCompleted('cobranza', cobranza.cobranzaMovilId);
    }
    return result;
  }

  Future<void> _saveLocally(CobranzaPendiente cobranza) async {
    final db = AppDatabase();
    await db.initialize();
    await db.cobranzaDao.insert(cobranza);
  }

  Future<Map<String, dynamic>> _syncOne(CobranzaPendiente cobranza) async {
    try {
      final response = await _dio.post(
        '/api/v1/cobranza/insert',
        data: cobranza.toJson(),
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final db = AppDatabase();
        await db.initialize();
        await db.cobranzaDao.updateAfterSync(
          cobranzaMovilId: cobranza.cobranzaMovilId,
          estado: 'enviada',
          doctoPvId: data['docto_pv_id'] as int?,
          folio: data['folio'] as String?,
        );
        return data;
      }
      throw Exception('Error al registrar cobranza: ${response.statusCode}');
    } catch (e) {
      return {
        'error': true,
        'message': 'Cobranza guardada localmente. Se sincronizara cuando haya conexion.',
      };
    }
  }

  Future<Map<String, dynamic>> uploadOne(String cobranzaMovilId) async {
    if (_isOffline) return {'error': true, 'message': 'offline'};
    try {
      final db = AppDatabase();
      await db.initialize();
      final pendientes = await db.cobranzaDao.getPendientes();
      final cobranza = pendientes.cast<CobranzaPendiente?>().firstWhere(
        (c) => c?.cobranzaMovilId == cobranzaMovilId,
        orElse: () => null,
      );
      if (cobranza == null) return {'error': true, 'message': 'cobranza_no_encontrada'};
      return await _syncOne(cobranza);
    } catch (e) {
      return {'error': true, 'message': e.toString()};
    }
  }

  Future<int> syncPending() async {
    if (_isOffline) return 0;
    final db = AppDatabase();
    await db.initialize();
    final pendientes = await db.cobranzaDao.getPendientes();
    int sincronizadas = 0;

    for (final cobranza in pendientes) {
      try {
        final response = await _dio.post(
          '/api/v1/cobranza/insert',
          data: cobranza.toJson(),
        );
        if (response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          await db.cobranzaDao.updateAfterSync(
            cobranzaMovilId: cobranza.cobranzaMovilId,
            estado: 'enviada',
            doctoPvId: data['docto_pv_id'] as int?,
            folio: data['folio'] as String?,
          );
          sincronizadas++;
        }
      } catch (_) {
        break;
      }
    }
    return sincronizadas;
  }
}

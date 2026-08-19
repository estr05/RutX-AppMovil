import 'dart:async';
import '../database/app_database.dart';
import '../database/daos/cola_sincronizacion_dao.dart';
import '../database/entities/cola_sincronizacion_entity.dart';
import 'connection_state_service.dart';

typedef SyncHandler = Future<Map<String, dynamic>> Function(String entidadId);

class SyncQueueProcessor {
  static const Duration _delayEntreItems = Duration(milliseconds: 1200);

  final AppDatabase _db;
  final Map<String, SyncHandler> _handlers = {};

  SyncQueueProcessor({AppDatabase? db}) : _db = db ?? AppDatabase();

  bool get _isOffline =>
      ConnectionStateService().currentState == RutxConnectionState.offline;

  ColaSincronizacionDao get _colaDao => _db.colaDao;

  void registerHandler(String tipo, SyncHandler handler) {
    _handlers[tipo] = handler;
  }

  Future<void> enqueue(String tipo, String entidadId) async {
    await _db.initialize();
    await _colaDao.insertIfNotExists(tipo, entidadId);
  }

  Future<int> processQueue() async {
    if (_isOffline) return 0;
    await _db.initialize();

    final items = await _colaDao.getPendientes();
    if (items.isEmpty) return 0;

    int procesados = 0;
    for (final item in items) {
      if (_isOffline) break;

      try {
        final result = await _procesarItem(item);
        if (result['success'] == true) {
          await _colaDao.marcarCompletado(item.id!);
          procesados++;
        } else {
          await _colaDao.marcarError(
            item.id!,
            result['error']?.toString() ?? 'Error desconocido',
          );
        }
      } catch (e) {
        await _colaDao.marcarError(item.id!, e.toString());
      }

      await Future.delayed(_delayEntreItems);
    }

    await _colaDao.deleteCompletados();
    return procesados;
  }

  Future<Map<String, dynamic>> processOne(String tipo, String entidadId) async {
    if (_isOffline) return {'success': false, 'error': 'offline'};
    await _db.initialize();

    final item = await _colaDao.getByTipoYEntidad(tipo, entidadId);
    if (item == null) return {'success': false, 'error': 'no_en_cola'};

    try {
      final result = await _procesarItem(item);
      if (result['success'] == true) {
        await _colaDao.marcarCompletado(item.id!);
      } else {
        await _colaDao.marcarError(
          item.id!,
          result['error']?.toString() ?? 'Error',
        );
      }
      return result;
    } catch (e) {
      await _colaDao.marcarError(item.id!, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> markCompleted(String tipo, String entidadId) async {
    await _db.initialize();
    final item = await _colaDao.getByTipoYEntidad(tipo, entidadId);
    if (item != null) {
      await _colaDao.marcarCompletado(item.id!);
    }
  }

  Future<Map<String, dynamic>> _procesarItem(ColaSincronizacion item) async {
    final handler = _handlers[item.tipo];
    if (handler == null) {
      return {'success': false, 'error': 'sin_handler: ${item.tipo}'};
    }
    return await handler(item.entidadId);
  }
}

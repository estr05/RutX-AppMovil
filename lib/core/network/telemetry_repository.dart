import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import '../device/device_identity_provider.dart';
import '../location/location_provider.dart';
import '../database/app_database.dart';
import '../database/entities/telemetria_pendiente_entity.dart';
import 'dio_client.dart';
import 'sync_queue_processor.dart';

class TelemetryRepository {
  static final TelemetryRepository _instance = TelemetryRepository._();
  factory TelemetryRepository() => _instance;
  TelemetryRepository._();

  final LocalStorage _storage = LocalStorage();
  final SyncQueueProcessor _queue = SyncQueueProcessor();

  /// Captura el evento y lo guarda INMEDIATAMENTE para evitar pérdida de datos.
  /// Luego busca el GPS en background y actualiza la BD. NUNCA lanza excepción.
  Future<void> captureAndQueue({
    required String eventType,
    int? customerId,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sellerId = await _storage.getVendedorId() ?? 0;
      if (sellerId == 0) return;

      final deviceInstallationId = await DeviceIdentityProvider().getOrCreateDeviceInstallationId();
      final clientEventId = const Uuid().v4();

      // 1. Guardar evento base inmediatamente (GPS en null)
      final entity = TelemetriaPendiente(
        clientEventId: clientEventId,
        eventType: eventType,
        customerId: customerId,
        relatedEntityId: relatedEntityId,
        sellerId: sellerId,
        contractNumber: 'N/A', // Requerido por el esquema de SQLite
        deviceInstallationId: deviceInstallationId,
        occurredAt: DateTime.now().toUtc().toIso8601String(),
        metadataJson: metadata != null ? jsonEncode(metadata) : null,
        creadoEn: DateTime.now().toIso8601String(),
      );

      final db = AppDatabase();
      await db.initialize();
      await db.telemetriaDao.insert(entity);
      await _queue.enqueue('telemetria', clientEventId);

      // 2. Buscar GPS en segundo plano y actualizar
      LocationProvider().getCurrentPosition().then((position) async {
        if (position != null) {
          await db.telemetriaDao.actualizarUbicacion(
            clientEventId,
            position.latitude,
            position.longitude,
            position.accuracy,
          );
        }
        // Intentar envío una vez finalizado todo (con o sin GPS)
        _queue.processOne('telemetria', clientEventId);
      });
    } catch (e) {
      // Silencioso — nunca interrumpir el flujo de negocio
      print('[Telemetría] captureAndQueue error: $e');
    }
  }

  Future<Map<String, dynamic>> sendOne(String clientEventId) async {
    final db = AppDatabase();
    await db.initialize();

    try {
      final item = await db.telemetriaDao.getById(clientEventId);
      if (item == null) return {'success': false, 'error': 'not_found'};

      final payload = {
        'client_event_id': item.clientEventId,
        'event_type': item.eventType,
        'customer_id': item.customerId,
        'related_entity_id': item.relatedEntityId,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'accuracy': item.accuracy,
        'occurred_at': item.occurredAt,
        'device_installation_id': item.deviceInstallationId,
        if (item.metadataJson != null) 'metadata': jsonDecode(item.metadataJson!),
      };

      try {
        await DioClient().dio.post('/api/v1/telemetry/events', data: payload);
        // 2xx: éxito
        await db.telemetriaDao.marcarEnviado(clientEventId, DateTime.now().toIso8601String());
        return {'success': true};
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        // F1: 409 = ya registrado con otro hash — marcar como enviado, no reintentar
        if (status == 409) {
          await db.telemetriaDao.marcarEnviado(clientEventId, DateTime.now().toIso8601String());
          return {'success': true};
        }

        final errMsg = 'http_$status';
        await db.telemetriaDao.incrementarReintento(clientEventId, errMsg);
        return {'success': false, 'error': errMsg};
      }
    } catch (e) {
      await db.telemetriaDao.incrementarReintento(clientEventId, e.toString());
      return {'success': false, 'error': e.toString()};
    }
  }
}

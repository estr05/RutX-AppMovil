import 'package:sqflite/sqflite.dart';
import '../entities/telemetria_pendiente_entity.dart';

class TelemetriaDao {
  final Database db;

  TelemetriaDao(this.db);

  Future<void> insert(TelemetriaPendiente item) async {
    await db.insert(
      'telemetria_pendiente',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<TelemetriaPendiente?> getById(String clientEventId) async {
    final maps = await db.query(
      'telemetria_pendiente',
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TelemetriaPendiente.fromMap(maps.first);
  }

  Future<List<TelemetriaPendiente>> pendientes() async {
    final maps = await db.query(
      'telemetria_pendiente',
      where: 'estado = ?',
      whereArgs: ['pendiente'],
      orderBy: 'creado_en ASC',
    );
    return maps.map((m) => TelemetriaPendiente.fromMap(m)).toList();
  }

  Future<void> marcarEnviado(String clientEventId, String fechaIso) async {
    await db.update(
      'telemetria_pendiente',
      {
        'estado': 'enviado',
        'enviado_en': fechaIso,
      },
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }

  Future<void> marcarError(String clientEventId, String error, String fechaIso) async {
    await db.update(
      'telemetria_pendiente',
      {
        'estado': 'error',
        'ultimo_error': error,
        'enviado_en': fechaIso, // se usa como timestamp del último intento
      },
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }

  Future<void> incrementarReintento(String clientEventId, String error) async {
    await db.rawUpdate(
      'UPDATE telemetria_pendiente SET reintentos = reintentos + 1, ultimo_error = ? WHERE client_event_id = ?',
      [error, clientEventId],
    );
  }

  Future<void> actualizarUbicacion(String clientEventId, double lat, double lon, double acc) async {
    await db.update(
      'telemetria_pendiente',
      {'latitude': lat, 'longitude': lon, 'accuracy': acc},
      where: 'client_event_id = ?',
      whereArgs: [clientEventId],
    );
  }
}

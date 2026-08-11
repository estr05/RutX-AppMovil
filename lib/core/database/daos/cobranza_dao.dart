import 'package:sqflite/sqflite.dart';
import '../entities/cobranza_pendiente_entity.dart';

class CobranzaDao {
  final Database db;

  CobranzaDao(this.db);

  Future<void> insert(CobranzaPendiente cobranza) async {
    await db.insert(
      'cobranzas_pendientes',
      cobranza.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CobranzaPendiente>> getPendientes() async {
    final maps = await db.query(
      'cobranzas_pendientes',
      where: 'estado = ?',
      whereArgs: ['pendiente'],
      orderBy: 'fecha_hora ASC',
    );
    return maps.map((m) => CobranzaPendiente.fromMap(m)).toList();
  }

  Future<List<CobranzaPendiente>> getAll() async {
    final maps = await db.query(
      'cobranzas_pendientes',
      orderBy: 'fecha_hora DESC',
    );
    return maps.map((m) => CobranzaPendiente.fromMap(m)).toList();
  }

  Future<List<CobranzaPendiente>> getDelDia(String? fecha) async {
    if (fecha == null || fecha.isEmpty) return getAll();
    final maps = await db.query(
      'cobranzas_pendientes',
      where: 'fecha_hora LIKE ?',
      whereArgs: ['$fecha%'],
      orderBy: 'fecha_hora ASC',
    );
    return maps.map((m) => CobranzaPendiente.fromMap(m)).toList();
  }

  Future<void> updateEstado(String cobranzaMovilId, String? estado) async {
    if (estado == null || estado.isEmpty) return;
    await db.update(
      'cobranzas_pendientes',
      {'estado': estado},
      where: 'cobranza_movil_id = ?',
      whereArgs: [cobranzaMovilId],
    );
  }

  Future<void> updateAfterSync({
    required String cobranzaMovilId,
    required String estado,
    int? doctoPvId,
    String? folio,
  }) async {
    final values = <String, dynamic>{'estado': estado};
    if (doctoPvId != null) values['docto_pv_id'] = doctoPvId;
    if (folio != null) values['folio'] = folio;
    await db.update(
      'cobranzas_pendientes',
      values,
      where: 'cobranza_movil_id = ?',
      whereArgs: [cobranzaMovilId],
    );
  }

  Future<CobranzaPendiente?> getById(String cobranzaMovilId) async {
    final maps = await db.query(
      'cobranzas_pendientes',
      where: 'cobranza_movil_id = ?',
      whereArgs: [cobranzaMovilId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CobranzaPendiente.fromMap(maps.first);
  }

  Future<void> deleteAll() async {
    await db.delete('cobranzas_pendientes');
  }
}

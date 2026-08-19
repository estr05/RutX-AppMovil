import 'package:sqflite/sqflite.dart';
import '../entities/cola_sincronizacion_entity.dart';

class ColaSincronizacionDao {
  final Database db;

  ColaSincronizacionDao(this.db);

  Future<int> insert(ColaSincronizacion item) async {
    return await db.insert(
      'cola_sincronizacion',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> insertIfNotExists(String tipo, String entidadId) async {
    final existing = await db.query(
      'cola_sincronizacion',
      where: 'tipo = ? AND entidad_id = ? AND estado != ?',
      whereArgs: [tipo, entidadId, 'completado'],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert(
      'cola_sincronizacion',
      ColaSincronizacion(
        tipo: tipo,
        entidadId: entidadId,
        creadoEn: DateTime.now().toIso8601String(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<ColaSincronizacion>> getPendientes() async {
    final maps = await db.query(
      'cola_sincronizacion',
      where: 'estado IN (?, ?)',
      whereArgs: ['pendiente', 'error'],
      orderBy: 'prioridad DESC, creado_en ASC',
    );
    return maps.map((m) => ColaSincronizacion.fromMap(m)).toList();
  }

  Future<int> getCantidadPendientes() async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM cola_sincronizacion WHERE estado IN ('pendiente', 'error')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<ColaSincronizacion?> getByTipoYEntidad(
    String tipo,
    String entidadId,
  ) async {
    final maps = await db.query(
      'cola_sincronizacion',
      where: 'tipo = ? AND entidad_id = ?',
      whereArgs: [tipo, entidadId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ColaSincronizacion.fromMap(maps.first);
  }

  Future<void> marcarCompletado(int id) async {
    await db.update(
      'cola_sincronizacion',
      {
        'estado': 'completado',
        'sincronizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> marcarError(int id, String error) async {
    await db.rawUpdate(
      'UPDATE cola_sincronizacion SET estado = ?, reintentos = reintentos + 1, ultimo_error = ? WHERE id = ?',
      ['error', error, id],
    );
  }

  Future<int> deleteCompletados() async {
    return await db.delete(
      'cola_sincronizacion',
      where: 'estado = ?',
      whereArgs: ['completado'],
    );
  }

  Future<void> limpiarTodo() async {
    await db.delete('cola_sincronizacion');
  }
}

import 'package:sqflite/sqflite.dart';
import '../entities/cliente_entity.dart';

class ClienteDao {
  final Database db;

  ClienteDao(this.db);

  Future<void> insertAll(List<Cliente> clientes) async {
    final batch = db.batch();
    for (final c in clientes) {
      batch.insert(
        'clientes',
        c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Cliente>> getAll() async {
    final maps = await db.query('clientes', orderBy: 'nombre_cliente ASC');
    return maps.map((m) => Cliente.fromMap(m)).toList();
  }

  /// Retorna los primeros [limit] clientes (carga perezosa).
  Future<List<Cliente>> getFirst(int limit) async {
    final maps = await db.query(
      'clientes',
      orderBy: 'nombre_cliente ASC',
      limit: limit,
    );
    return maps.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<Cliente?> getById(int clienteId) async {
    final maps = await db.query(
      'clientes',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Cliente.fromMap(maps.first);
  }

  Future<List<Cliente>> search(String? query) async {
    if (query == null || query.isEmpty) return getAll();
    final maps = await db.query(
      'clientes',
      where: 'nombre_cliente LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nombre_cliente ASC',
    );
    return maps.map((m) => Cliente.fromMap(m)).toList();
  }

  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM clientes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Retorna los ids de todos los clientes locales (para comparar descargas).
  Future<Set<int>> getAllIds() async {
    final rows = await db.rawQuery('SELECT cliente_id FROM clientes');
    return rows.map((r) => r['cliente_id'] as int).toSet();
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'clientes',
      where: 'cliente_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> deleteAll() async {
    await db.delete('clientes');
  }
}

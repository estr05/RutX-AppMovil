import 'package:sqflite/sqflite.dart';
import '../entities/producto_entity.dart';

class ProductoDao {
  final Database db;

  ProductoDao(this.db);

  Future<void> insertAll(List<Producto> productos) async {
    final batch = db.batch();
    for (final p in productos) {
      batch.insert('productos', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Producto>> getAll() async {
    final maps = await db.query(
      'productos',
      where: 'estatus = ?',
      whereArgs: ['A'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  /// Retorna los primeros [limit] productos activos (carga perezosa).
  Future<List<Producto>> getFirst(int limit) async {
    final maps = await db.query(
      'productos',
      where: 'estatus = ?',
      whereArgs: ['A'],
      orderBy: 'nombre ASC',
      limit: limit,
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  Future<Producto?> getById(int articuloId) async {
    final maps = await db.query(
      'productos',
      where: 'articulo_id = ?',
      whereArgs: [articuloId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Producto.fromMap(maps.first);
  }

  Future<List<Producto>> search(String? query) async {
    if (query == null || query.isEmpty) return getAll();
    final maps = await db.query(
      'productos',
      where:
          '(nombre LIKE ? OR clave LIKE ? OR CAST(articulo_id AS TEXT) LIKE ?) AND estatus = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 'A'],
      orderBy: 'nombre ASC',
    );
    return maps.map((m) => Producto.fromMap(m)).toList();
  }

  Future<int> count() async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM productos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Retorna los ids de todos los productos locales (para comparar descargas).
  Future<Set<int>> getAllIds() async {
    final rows = await db.rawQuery('SELECT articulo_id FROM productos');
    return rows.map((r) => r['articulo_id'] as int).toSet();
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'productos',
      where: 'articulo_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> deleteAll() async {
    await db.delete('productos');
  }
}

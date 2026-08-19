import 'package:sqflite/sqflite.dart';
import '../entities/causa_no_venta_entity.dart';

class CausaNoVentaDao {
  final Database db;

  CausaNoVentaDao(this.db);

  Future<void> insertAll(List<CausaNoVenta> causas) async {
    final batch = db.batch();
    for (var causa in causas) {
      batch.insert(
        'causas_no_venta',
        causa.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CausaNoVenta>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'causas_no_venta',
      where: 'estatus = ?',
      whereArgs: ['A'],
      orderBy: 'descripcion ASC',
    );

    return List.generate(maps.length, (i) {
      return CausaNoVenta.fromMap(maps[i]);
    });
  }

  Future<int> count() async {
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM causas_no_venta'),
        ) ??
        0;
  }

  Future<void> deleteAll() async {
    await db.delete('causas_no_venta');
  }
}

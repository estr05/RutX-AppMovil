import 'package:sqflite/sqflite.dart';
import '../entities/sucursal_entity.dart';

class SucursalDao {
  final Database db;

  SucursalDao(this.db);

  // Solo hay una sucursal activa por ruta, se guarda con id fijo = 1
  static const int _rowId = 1;

  Future<void> insert(Sucursal sucursal) async {
    await db.insert(
      'sucursal',
      {'id': _rowId, ...sucursal.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Sucursal?> get() async {
    final maps = await db.query('sucursal', where: 'id = ?', whereArgs: [_rowId], limit: 1);
    if (maps.isEmpty) return null;
    return Sucursal.fromMap(maps.first);
  }

  Future<void> delete() async {
    await db.delete('sucursal');
  }
}

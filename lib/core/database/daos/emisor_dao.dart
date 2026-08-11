import 'package:sqflite/sqflite.dart';
import '../entities/emisor_entity.dart';

class EmisorDao {
  final Database db;

  EmisorDao(this.db);

  // Solo hay un emisor (la empresa), se guarda con id fijo = 1
  static const int _rowId = 1;

  Future<void> insert(Emisor emisor) async {
    await db.insert(
      'emisor',
      {'id': _rowId, ...emisor.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Emisor?> get() async {
    final maps = await db.query('emisor', where: 'id = ?', whereArgs: [_rowId], limit: 1);
    if (maps.isEmpty) return null;
    return Emisor.fromMap(maps.first);
  }

  Future<void> delete() async {
    await db.delete('emisor');
  }
}

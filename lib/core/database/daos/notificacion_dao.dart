import 'package:sqflite/sqflite.dart';
import '../entities/notificacion_entity.dart';

class NotificacionDao {
  final Database db;

  NotificacionDao(this.db);

  Future<void> insertAll(List<Notificacion> notificaciones) async {
    final batch = db.batch();
    for (final n in notificaciones) {
      batch.insert(
        'notificaciones',
        n.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Notificacion>> getAll() async {
    final maps = await db.query(
      'notificaciones',
      orderBy: 'fecha_creacion DESC',
    );
    return maps.map((m) => Notificacion.fromMap(m)).toList();
  }

  Future<List<Notificacion>> getNoLeidas() async {
    final maps = await db.query(
      'notificaciones',
      where: 'leida = ?',
      whereArgs: [0],
      orderBy: 'fecha_creacion DESC',
    );
    return maps.map((m) => Notificacion.fromMap(m)).toList();
  }

  Future<int> countNoLeidas() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notificaciones WHERE leida = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markAsRead(int id) async {
    await db.update(
      'notificaciones',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    await db.update('notificaciones', {'leida': 1});
  }

  Future<void> updateMensaje(int id, String nuevoMensaje) async {
    await db.update(
      'notificaciones',
      {'mensaje': nuevoMensaje, 'leida': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    await db.delete('notificaciones');
  }
}

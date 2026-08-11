import '../../../../core/database/app_database.dart';
import '../../../../core/database/entities/notificacion_entity.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource = NotificationRemoteDataSource();

  Future<String?> fetchAndPersist(int vendedorId) async {
    try {
      final db = AppDatabase();
      await db.initialize();

      final existing = await db.notificacionDao.getAll();
      final existingKeys = existing.map((n) => n.mensaje).toSet();

      final remotos = await _remoteDataSource.fetchNotificaciones(vendedorId);

      final nuevas = <Notificacion>[];
      for (final r in remotos) {
        final key = r.contenido;
        if (!existingKeys.contains(key)) {
          nuevas.add(Notificacion(
            mensaje: key,
            fechaCreacion: r.fechaEnvio,
          ));
        }
      }

      if (nuevas.isNotEmpty) {
        await db.notificacionDao.insertAll(nuevas);
      }
      return null;
    } catch (e) {
      return 'Error al descargar notificaciones.';
    }
  }

  Future<List<Notificacion>> getAll() async {
    final db = AppDatabase();
    await db.initialize();
    return db.notificacionDao.getAll();
  }

  Future<int> getUnreadCount() async {
    final db = AppDatabase();
    await db.initialize();
    return db.notificacionDao.countNoLeidas();
  }

  Future<String?> markAsRead(int id) async {
    try {
      final db = AppDatabase();
      await db.initialize();
      await db.notificacionDao.markAsRead(id);
      return null;
    } catch (_) {
      return 'Error al marcar como leída.';
    }
  }

  Future<String?> updateMensaje(int id, String nuevoMensaje) async {
    try {
      final db = AppDatabase();
      await db.initialize();
      await db.notificacionDao.updateMensaje(id, nuevoMensaje);
      return null;
    } catch (_) {
      return 'Error al confirmar notificación.';
    }
  }

  Future<String?> markAllAsRead() async {
    try {
      final db = AppDatabase();
      await db.initialize();
      await db.notificacionDao.markAllAsRead();
      return null;
    } catch (_) {
      return 'Error al marcar todas como leídas.';
    }
  }

  Future<String?> deleteAll() async {
    try {
      final db = AppDatabase();
      await db.initialize();
      await db.notificacionDao.deleteAll();
      return null;
    } catch (_) {
      return 'Error al eliminar notificaciones.';
    }
  }

  Future<String?> reseed() async {
    try {
      final db = AppDatabase();
      await db.initialize();
      await db.notificacionDao.deleteAll();
      await db.seedDatabase();
      return null;
    } catch (_) {
      return 'Error al restablecer notificaciones.';
    }
  }
}

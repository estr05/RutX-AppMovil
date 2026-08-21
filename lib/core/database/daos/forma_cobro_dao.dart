import 'package:sqflite/sqflite.dart';
import '../entities/forma_cobro_entity.dart';

/// DAO encargado del acceso a datos para las Formas de Cobro dinámicas en SQLite.
class FormaCobroDao {
  final Database db;

  FormaCobroDao(this.db);

  /// Inserta o reemplaza un lote de formas de cobro dinámicas provenientes del servidor.
  Future<void> insertAll(List<FormaCobro> formas) async {
    final batch = db.batch();
    for (var forma in formas) {
      batch.insert(
        'formas_cobro',
        forma.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Obtiene todas las formas de cobro activas.
  Future<List<FormaCobro>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'formas_cobro',
      where: 'estatus = ?',
      whereArgs: ['A'],
      orderBy: 'nombre ASC',
    );

    return List.generate(maps.length, (i) => FormaCobro.fromMap(maps[i]));
  }

  /// Obtiene la primera forma de cobro de tipo Contado (tipo = 'C').
  Future<FormaCobro?> getFormaContadoDefault() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'formas_cobro',
      where: 'tipo = ? AND estatus = ?',
      whereArgs: ['C', 'A'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return FormaCobro.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene las formas de cobro filtradas por su tipo ('C' = Contado, 'R' = Crédito).
  Future<List<FormaCobro>> getByTipo(String tipo) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'formas_cobro',
      where: 'tipo = ? AND estatus = ?',
      whereArgs: [tipo.toUpperCase(), 'A'],
      orderBy: 'nombre ASC',
    );

    return List.generate(maps.length, (i) => FormaCobro.fromMap(maps[i]));
  }

  /// Elimina todas las formas de cobro locales antes de re-sincronizar.
  Future<void> deleteAll() async {
    await db.delete('formas_cobro');
  }
}

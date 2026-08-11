import 'package:sqflite/sqflite.dart';
import '../entities/folio_local_entity.dart';

/// Contador de folios provisionales locales, uno por cajero.
///
/// El consecutivo se incrementa de forma atómica dentro de una transacción
/// para que cada venta offline reciba un folio único y consecutivo, incluso
/// si el dispositivo reinicia o hay múltiples hilos de confirmación.
class FolioLocalDao {
  static const String _serie = 'PRV';

  final Database db;

  FolioLocalDao(this.db);

  /// Obtiene el siguiente folio provisional: `PRV-0000001`, `PRV-0000002`, ...
  Future<String> siguienteFolioProvisional(int cajeroId) async {
    int numero = 0;
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO folios_locales (cajero_id, consecutivo, actualizado_en) VALUES (?, 0, ?)',
        [cajeroId, DateTime.now().toIso8601String()],
      );
      await txn.rawUpdate(
        'UPDATE folios_locales SET consecutivo = consecutivo + 1, actualizado_en = ? WHERE cajero_id = ?',
        [DateTime.now().toIso8601String(), cajeroId],
      );
      final rows = await txn.rawQuery(
        'SELECT consecutivo FROM folios_locales WHERE cajero_id = ?',
        [cajeroId],
      );
      numero = (rows.first['consecutivo'] as num).toInt();
    });
    return '$_serie-${numero.toString().padLeft(7, '0')}';
  }

  Future<FolioLocal?> getByCajero(int cajeroId) async {
    final rows = await db.query(
      'folios_locales',
      where: 'cajero_id = ?',
      whereArgs: [cajeroId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FolioLocal.fromMap(rows.first);
  }

  Future<void> reset(int cajeroId) async {
    await db.update(
      'folios_locales',
      {'consecutivo': 0},
      where: 'cajero_id = ?',
      whereArgs: [cajeroId],
    );
  }
}

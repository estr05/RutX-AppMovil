import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../entities/venta_pendiente_entity.dart';

class VentaDao {
  final Database db;

  VentaDao(this.db);

  Future<void> insert(VentaPendiente venta) async {
    await db.insert(
      'ventas_pendientes',
      venta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VentaPendiente>> getPendientes() async {
    final maps = await db.query(
      'ventas_pendientes',
      where: 'estado = ?',
      whereArgs: ['pendiente'],
      orderBy: 'fecha_hora ASC',
    );
    return maps.map((m) => VentaPendiente.fromMap(m)).toList();
  }

  Future<List<VentaPendiente>> getByEstado(String? estado) async {
    if (estado == null || estado.isEmpty) return getAll();
    final maps = await db.query(
      'ventas_pendientes',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha_hora ASC',
    );
    return maps.map((m) => VentaPendiente.fromMap(m)).toList();
  }

  Future<List<VentaPendiente>> getAll() async {
    final maps = await db.query(
      'ventas_pendientes',
      orderBy: 'fecha_hora DESC',
    );
    return maps.map((m) => VentaPendiente.fromMap(m)).toList();
  }

  Future<List<VentaPendiente>> getDelDia(String? fecha) async {
    if (fecha == null || fecha.isEmpty) return getAll();
    final maps = await db.query(
      'ventas_pendientes',
      where: 'fecha_hora LIKE ?',
      whereArgs: ['$fecha%'],
      orderBy: 'fecha_hora ASC',
    );
    return maps.map((m) => VentaPendiente.fromMap(m)).toList();
  }

  Future<void> updateEstado(String ventaMovilId, String? estado) async {
    if (estado == null || estado.isEmpty) return;
    await db.update(
      'ventas_pendientes',
      {'estado': estado},
      where: 'venta_movil_id = ?',
      whereArgs: [ventaMovilId],
    );
  }

  /// Actualiza los datos devueltos por Microsip despues de sincronizar.
  /// [doctoPvId] es el ID del ticket en DOCTOS_PV.
  /// [folio] es el numero de ticket generado (ej: V000000123).
  Future<void> updateAfterSync({
    required String ventaMovilId,
    required String estado,
    int? doctoPvId,
    String? folio,
  }) async {
    final values = <String, dynamic>{'estado': estado};
    if (doctoPvId != null) values['docto_pv_id'] = doctoPvId;
    if (folio != null) values['folio'] = folio;

    await db.update(
      'ventas_pendientes',
      values,
      where: 'venta_movil_id = ?',
      whereArgs: [ventaMovilId],
    );
  }

  Future<VentaPendiente?> getById(String ventaMovilId) async {
    final maps = await db.query(
      'ventas_pendientes',
      where: 'venta_movil_id = ?',
      whereArgs: [ventaMovilId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return VentaPendiente.fromMap(maps.first);
  }

  Future<Map<String, dynamic>> getResumenDelDia(String fecha) async {
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_ventas,
        COALESCE(SUM(total), 0) as monto_total,
        COUNT(CASE WHEN estado = 'pendiente' THEN 1 END) as pendientes,
        COUNT(CASE WHEN estado = 'enviada' THEN 1 END) as enviadas,
        COUNT(CASE WHEN estado = 'error' THEN 1 END) as con_error
      FROM ventas_pendientes
      WHERE fecha_hora LIKE ?
    ''',
      ['$fecha%'],
    );

    final jsonRows = await db.rawQuery(
      '''
      SELECT detalles_json FROM ventas_pendientes WHERE fecha_hora LIKE ?
    ''',
      ['$fecha%'],
    );

    int piezas = 0;
    for (final row in jsonRows) {
      final json = row['detalles_json'] as String?;
      if (json == null || json.isEmpty) continue;
      final arr = _parseDetalles(json);
      for (final det in arr) {
        piezas += (det['unidades'] as num?)?.toInt() ?? 0;
      }
    }

    if (result.isEmpty) {
      return {
        'total_ventas': 0,
        'monto_total': 0.0,
        'pendientes': 0,
        'enviadas': 0,
        'con_error': 0,
        'piezas_vendidas': piezas,
      };
    }

    final map = Map<String, dynamic>.from(result.first);
    map['piezas_vendidas'] = piezas;
    return map;
  }

  List<dynamic> _parseDetalles(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteAll() async {
    await db.delete('ventas_pendientes');
  }

  // ==========================================================================
  // EXISTENCIAS DEL ALMACÉN (flujo offline-first)
  // El stock local (`productos.existencias`) se descuenta al confirmar la
  // venta y se revierte si el servidor la rechaza de forma definitiva.
  // ==========================================================================

  /// Inserta la venta y descuenta las existencias del almacén en una sola
  /// transacción. Retorna `false` (con rollback) si algún artículo no tiene
  /// existencia suficiente, evitando la sobreventa aunque la app esté offline.
  Future<bool> insertDescontandoExistencia(VentaPendiente venta) async {
    try {
      await db.transaction((txn) async {
        await txn.insert(
          'ventas_pendientes',
          venta.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final cantidades = cantidadesPorArticulo(venta.detalles);
        for (final entry in cantidades.entries) {
          final changes = await txn.rawUpdate(
            'UPDATE productos SET existencias = existencias - ? '
            'WHERE articulo_id = ? AND existencias >= ?',
            [entry.value, entry.key, entry.value],
          );
          if (changes == 0) {
            throw StateError(
              'Existencia insuficiente para el artículo ${entry.key}',
            );
          }
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Suma de vuelta las existencias de los artículos de la venta.
  /// Se usa cuando el servidor rechaza la venta de forma definitiva (4xx):
  /// esas unidades nunca salieron del almacén real.
  Future<void> reponerExistencias(VentaPendiente venta) async {
    final cantidades = cantidadesPorArticulo(venta.detalles);
    await db.transaction((txn) async {
      for (final entry in cantidades.entries) {
        await txn.rawUpdate(
          'UPDATE productos SET existencias = existencias + ? '
          'WHERE articulo_id = ?',
          [entry.value, entry.key],
        );
      }
    });
  }

  /// Resta las existencias de los artículos de la venta (con piso en 0).
  /// Se usa cuando una venta en estado 'error' (cuyo stock se había
  /// revertido) se reenvía con éxito: las unidades sí salieron del almacén.
  Future<void> descontarExistencias(VentaPendiente venta) async {
    final cantidades = cantidadesPorArticulo(venta.detalles);
    await db.transaction((txn) async {
      for (final entry in cantidades.entries) {
        await txn.rawUpdate(
          'UPDATE productos SET existencias = MAX(0, existencias - ?) '
          'WHERE articulo_id = ?',
          [entry.value, entry.key],
        );
      }
    });
  }

  /// Marca la venta como 'error' (rechazo definitivo del servidor) y revierte
  /// las existencias descontadas, en una sola transacción. Es idempotente:
  /// solo revierte si la venta venía de 'pendiente'.
  Future<void> marcarErrorRevertirExistencia(VentaPendiente venta) async {
    await db.transaction((txn) async {
      final rows = await txn.query(
        'ventas_pendientes',
        columns: ['estado'],
        where: 'venta_movil_id = ? AND estado = ?',
        whereArgs: [venta.ventaMovilId, 'pendiente'],
      );
      if (rows.isEmpty) {
        return; // Ya no estaba pendiente: no revertir dos veces.
      }

      await txn.update(
        'ventas_pendientes',
        {'estado': 'error'},
        where: 'venta_movil_id = ?',
        whereArgs: [venta.ventaMovilId],
      );
      final cantidades = cantidadesPorArticulo(venta.detalles);
      for (final entry in cantidades.entries) {
        await txn.rawUpdate(
          'UPDATE productos SET existencias = existencias + ? '
          'WHERE articulo_id = ?',
          [entry.value, entry.key],
        );
      }
    });
  }

  /// Re-aplica el descuento de las ventas aún no sincronizadas ('pendiente')
  /// sobre las existencias. Se invoca tras una descarga que sobrescribió
  /// `existencias` con el valor del servidor; sin esto el stock local
  /// "regresaría" y permitiría sobreventa offline.
  Future<void> reaplicarExistenciasPendientes() async {
    final pendientes = await getPendientes();
    await db.transaction((txn) async {
      for (final v in pendientes) {
        final cantidades = cantidadesPorArticulo(v.detalles);
        for (final entry in cantidades.entries) {
          await txn.rawUpdate(
            'UPDATE productos SET existencias = MAX(0, existencias - ?) '
            'WHERE articulo_id = ?',
            [entry.value, entry.key],
          );
        }
      }
    });
  }
}

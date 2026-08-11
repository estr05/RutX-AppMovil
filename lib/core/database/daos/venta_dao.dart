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
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_ventas,
        COALESCE(SUM(total), 0) as monto_total,
        COUNT(CASE WHEN estado = 'pendiente' THEN 1 END) as pendientes,
        COUNT(CASE WHEN estado = 'enviada' THEN 1 END) as enviadas,
        COUNT(CASE WHEN estado = 'error' THEN 1 END) as con_error
      FROM ventas_pendientes
      WHERE fecha_hora LIKE ?
    ''', ['$fecha%']);

    final jsonRows = await db.rawQuery('''
      SELECT detalles_json FROM ventas_pendientes WHERE fecha_hora LIKE ?
    ''', ['$fecha%']);

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
}

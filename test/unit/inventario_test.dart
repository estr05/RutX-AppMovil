import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rutx_movil/core/database/daos/producto_dao.dart';
import 'package:rutx_movil/core/database/daos/venta_dao.dart';
import 'package:rutx_movil/core/database/entities/producto_entity.dart';
import 'package:rutx_movil/core/database/entities/venta_pendiente_entity.dart';

DatabaseFactory _factory = databaseFactoryFfi;

Future<Database> _openDb() => _factory.openDatabase(inMemoryDatabasePath);

const _createProductos = '''
  CREATE TABLE productos (
    articulo_id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    estatus TEXT DEFAULT 'A',
    clave TEXT,
    precio REAL,
    precio_con_impuesto REAL DEFAULT 0.0,
    porcentaje_impuesto INTEGER DEFAULT 16,
    impuesto_id INTEGER DEFAULT 622,
    impuestos_json TEXT,
    existencias_gral REAL DEFAULT 0.0,
    existencias REAL DEFAULT 0.0,
    peso REAL DEFAULT 0.0,
    merma REAL DEFAULT 0.0,
    permite_merma TEXT DEFAULT 'No'
  )
''';

const _createVentasPendientes = '''
  CREATE TABLE ventas_pendientes (
    venta_movil_id TEXT PRIMARY KEY,
    vendedor_id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    cliente_nombre TEXT NOT NULL,
    fecha_hora TEXT NOT NULL,
    estado TEXT DEFAULT 'pendiente',
    total REAL DEFAULT 0.0,
    detalles_json TEXT,
    forma_cobro_id INTEGER DEFAULT 67,
    caja_id INTEGER,
    cajero_id INTEGER,
    almacen_id INTEGER,
    sucursal_id INTEGER,
    usuario_creador TEXT,
    docto_pv_id INTEGER,
    folio TEXT,
    folio_local TEXT,
    pagos_json TEXT
  )
''';

VentaPendiente _venta(
  String id, {
  String estado = 'pendiente',
  List<Map<String, dynamic>>? detalles,
}) =>
    VentaPendiente(
      ventaMovilId: id,
      vendedorId: 1,
      clienteId: 1,
      clienteNombre: 'Cliente',
      fechaHora: '2026-08-12T10:00:00.000',
      estado: estado,
      total: 100.0,
      detalles: detalles ??
          [
            {'articulo_id': 1, 'unidades': 1, 'precio_unitario': 100.0},
          ],
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Database db;
  late VentaDao ventaDao;
  late ProductoDao productDao;

  setUp(() async {
    db = await _openDb();
    await db.execute(_createProductos);
    await db.execute(_createVentasPendientes);
    ventaDao = VentaDao(db);
    productDao = ProductoDao(db);
    await productDao.insertAll([
      Producto(articuloId: 1, nombre: 'Tostadas 500g', clave: 'TOS001', precio: 20.0, existencias: 2.0),
      Producto(articuloId: 2, nombre: 'Refresco 600ml', clave: 'REF001', precio: 15.0, existencias: 10.0),
      Producto(articuloId: 3, nombre: 'Agua 1L', clave: 'AGU001', precio: 10.0, existencias: 0.0),
    ]);
  });

  tearDown(() => db.close());

  group('insertDescontandoExistencia', () {
    test('guarda la venta y descuenta existencias del almacén', () async {
      final guardada = await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
        ]),
      );

      expect(guardada, isTrue);

      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 0.0); // 2 - 2

      final venta = await ventaDao.getById('VTA-001');
      expect(venta, isNotNull);
      expect(venta!.estado, 'pendiente');
    });

    test('NO guarda la venta si no hay existencia suficiente (rollback)', () async {
      // Tostadas tiene solo 2; se intenta vender 3.
      final guardada = await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 3, 'precio_unitario': 20.0},
        ]),
      );

      expect(guardada, isFalse);

      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 2.0); // Sin cambios
      expect(await ventaDao.getById('VTA-001'), isNull); // No se insertó
    });

    test('hace rollback completo si alguna línea falla', () async {
      // Línea 1 válida (2 tostadas), línea 2 inválida (1 agua, hay 0).
      final guardada = await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
          {'articulo_id': 3, 'unidades': 1, 'precio_unitario': 10.0},
        ]),
      );

      expect(guardada, isFalse);

      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 2.0); // La línea 1 también se revirtió
      expect(await ventaDao.getById('VTA-001'), isNull);
    });

    test('bloquea sobreventa aunque la existencia sea fraccionaria', () async {
      // 2.5 unidades disponibles: solo se pueden vender 2 piezas enteras.
      await db.update(
        'productos',
        {'existencias': 2.5},
        where: 'articulo_id = ?',
        whereArgs: [1],
      );

      final guardada = await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 3, 'precio_unitario': 20.0},
        ]),
      );

      expect(guardada, isFalse);
      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 2.5);
    });
  });

  group('reponerExistencias', () {
    test('suma de vuelta las existencias de la venta', () async {
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
        ]),
      );
      final venta = (await ventaDao.getById('VTA-001'))!;

      await ventaDao.reponerExistencias(venta);

      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 2.0); // 0 + 2
    });
  });

  group('descontarExistencias', () {
    test('resta con piso en cero', () async {
      // Existencia 0.5: descontar 2 no debe dejar negativo.
      await db.update(
        'productos',
        {'existencias': 0.5},
        where: 'articulo_id = ?',
        whereArgs: [1],
      );

      await ventaDao.descontarExistencias(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
        ]),
      );

      final p1 = await productDao.getById(1);
      expect(p1!.existencias, 0.0);
    });
  });

  group('marcarErrorRevertirExistencia', () {
    test('marca error y revierte las existencias', () async {
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
        ]),
      );
      final venta = (await ventaDao.getById('VTA-001'))!;
      expect((await productDao.getById(1))!.existencias, 0.0);

      await ventaDao.marcarErrorRevertirExistencia(venta);

      expect((await ventaDao.getById('VTA-001'))!.estado, 'error');
      expect((await productDao.getById(1))!.existencias, 2.0);
    });

    test('es idempotente: no revierte dos veces', () async {
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 2, 'precio_unitario': 20.0},
        ]),
      );
      final venta = (await ventaDao.getById('VTA-001'))!;

      await ventaDao.marcarErrorRevertirExistencia(venta);
      await ventaDao.marcarErrorRevertirExistencia(venta);

      expect((await productDao.getById(1))!.existencias, 2.0);
    });
  });

  group('reaplicarExistenciasPendientes', () {
    test('re-aplica el descuento de ventas pendientes tras re-sync', () async {
      // El vendedor confirma 2 ventas (stock 2 -> 0) y después un re-sync
      // sobrescribe el stock con el valor del servidor (2, sin ventas).
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 1, 'precio_unitario': 20.0},
        ]),
      );
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-002', detalles: [
          {'articulo_id': 1, 'unidades': 1, 'precio_unitario': 20.0},
        ]),
      );
      // Simula la descarga del servidor (sobrescribe existencias).
      await productDao.insertAll([
        Producto(articuloId: 1, nombre: 'Tostadas 500g', clave: 'TOS001', precio: 20.0, existencias: 2.0),
      ]);
      expect((await productDao.getById(1))!.existencias, 2.0);

      await ventaDao.reaplicarExistenciasPendientes();

      // Las 2 ventas pendientes descuentan de nuevo: 2 - 1 - 1 = 0.
      expect((await productDao.getById(1))!.existencias, 0.0);
    });

    test('ignora ventas ya enviadas y con error', () async {
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-001', detalles: [
          {'articulo_id': 1, 'unidades': 1, 'precio_unitario': 20.0},
        ]),
      );
      await db.update(
        'ventas_pendientes',
        {'estado': 'enviada'},
        where: 'venta_movil_id = ?',
        whereArgs: ['VTA-001'],
      );
      await ventaDao.insertDescontandoExistencia(
        _venta('VTA-002', detalles: [
          {'articulo_id': 2, 'unidades': 1, 'precio_unitario': 15.0},
        ]),
      );
      await db.update(
        'ventas_pendientes',
        {'estado': 'error'},
        where: 'venta_movil_id = ?',
        whereArgs: ['VTA-002'],
      );

      // Re-sync: stock del servidor 2 y 10.
      await productDao.insertAll([
        Producto(articuloId: 1, nombre: 'Tostadas 500g', clave: 'TOS001', precio: 20.0, existencias: 2.0),
        Producto(articuloId: 2, nombre: 'Refresco 600ml', clave: 'REF001', precio: 15.0, existencias: 10.0),
      ]);

      await ventaDao.reaplicarExistenciasPendientes();

      // Sin pendientes: el stock queda como lo mandó el servidor.
      expect((await productDao.getById(1))!.existencias, 2.0);
      expect((await productDao.getById(2))!.existencias, 10.0);
    });
  });
}

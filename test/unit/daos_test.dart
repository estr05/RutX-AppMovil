import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rutx_movil/core/database/daos/cliente_dao.dart';
import 'package:rutx_movil/core/database/daos/producto_dao.dart';
import 'package:rutx_movil/core/database/daos/venta_dao.dart';
import 'package:rutx_movil/core/database/daos/cobranza_dao.dart';
import 'package:rutx_movil/core/database/entities/cliente_entity.dart';
import 'package:rutx_movil/core/database/entities/producto_entity.dart';
import 'package:rutx_movil/core/database/entities/venta_pendiente_entity.dart';
import 'package:rutx_movil/core/database/entities/cobranza_pendiente_entity.dart';

DatabaseFactory _factory = databaseFactoryFfi;

Future<Database> _openDb() => _factory.openDatabase(inMemoryDatabasePath);

const _createClientes = '''
  CREATE TABLE clientes (
    cliente_id INTEGER PRIMARY KEY,
    clave TEXT DEFAULT "",
    nombre_cliente TEXT NOT NULL,
    telefono TEXT DEFAULT "",
    calle TEXT,
    colonia TEXT,
    poblacion TEXT DEFAULT "",
    codigo_postal TEXT,
    limite_credito REAL DEFAULT 0.0,
    saldo REAL DEFAULT 0.0,
    tipo_venta INTEGER DEFAULT 1,
    cliente_rfc TEXT
  )
''';

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

const _createCobranzasPendientes = '''
  CREATE TABLE cobranzas_pendientes (
    cobranza_movil_id TEXT PRIMARY KEY,
    vendedor_id INTEGER NOT NULL,
    cliente_id INTEGER NOT NULL,
    cliente_nombre TEXT NOT NULL,
    fecha_hora TEXT NOT NULL,
    estado TEXT DEFAULT 'pendiente',
    total_cobrado REAL DEFAULT 0.0,
    pagos_json TEXT,
    documentos_json TEXT,
    docto_pv_id INTEGER,
    folio TEXT
  )
''';

Cliente _c(int id, String nombre, {String clave = ''}) => Cliente(
  clienteId: id,
  clave: clave,
  nombreCliente: nombre,
  telefono: '',
  poblacion: '',
  tipoVenta: 1,
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('ClienteDao', () {
    late Database db;
    late ClienteDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createClientes);
      dao = ClienteDao(db);
    });

    tearDown(() => db.close());

    group('insertAll', () {
      test('inserta mÃºltiples clientes', () async {
        await dao.insertAll([
          _c(1, 'Cliente A', clave: 'C001'),
          _c(2, 'Cliente B', clave: 'C002'),
        ]);

        final all = await dao.getAll();
        expect(all.length, 2);
      });
    });

    group('getAll', () {
      test('retorna lista vacÃ­a cuando no hay datos', () async {
        final all = await dao.getAll();
        expect(all, isEmpty);
      });

      test('retorna clientes ordenados por nombre', () async {
        await dao.insertAll([
          _c(2, 'Beta', clave: 'C002'),
          _c(1, 'Alfa', clave: 'C001'),
        ]);

        final all = await dao.getAll();
        expect(all.first.clienteId, 1);
        expect(all.first.nombreCliente, 'Alfa');
      });
    });

    group('getById', () {
      test('retorna null si no existe', () async {
        final c = await dao.getById(999);
        expect(c, isNull);
      });

      test('retorna el cliente correcto', () async {
        await dao.insertAll([_c(5, 'Encontrado', clave: 'C005')]);

        final c = await dao.getById(5);
        expect(c, isNotNull);
        expect(c!.nombreCliente, 'Encontrado');
      });
    });

    group('search', () {
      test('retorna todos cuando query es null', () async {
        await dao.insertAll([
          _c(1, 'Uno', clave: 'C001'),
          _c(2, 'Dos', clave: 'C002'),
        ]);

        final result = await dao.search(null);
        expect(result.length, 2);
      });

      test('retorna todos cuando query es vacÃ­o', () async {
        await dao.insertAll([_c(1, 'Uno', clave: 'C001')]);

        final result = await dao.search('');
        expect(result.length, 1);
      });

      test('filtra por nombre', () async {
        await dao.insertAll([
          _c(1, 'Juan PÃ©rez', clave: 'C001'),
          _c(2, 'MarÃ­a LÃ³pez', clave: 'C002'),
        ]);

        final result = await dao.search('Juan');
        expect(result.length, 1);
        expect(result.first.clienteId, 1);
      });
    });

    group('count', () {
      test('retorna 0 cuando no hay clientes', () async {
        expect(await dao.count(), 0);
      });

      test('retorna el nÃºmero correcto', () async {
        await dao.insertAll([
          _c(1, 'A', clave: 'C001'),
          _c(2, 'B', clave: 'C002'),
          _c(3, 'C', clave: 'C003'),
        ]);

        expect(await dao.count(), 3);
      });
    });

    group('deleteByIds', () {
      test('elimina solo los clientes especificados por ID', () async {
        await dao.insertAll([
          _c(1, 'A', clave: 'C001'),
          _c(2, 'B', clave: 'C002'),
          _c(3, 'C', clave: 'C003'),
        ]);
        await dao.deleteByIds([1, 3]);

        final remaining = await dao.getAll();
        expect(remaining.length, 1);
        expect(remaining.first.clienteId, 2);
      });

      test('no hace nada si la lista estÃ¡ vacÃ­a', () async {
        await dao.insertAll([_c(1, 'A', clave: 'C001')]);
        await dao.deleteByIds([]);

        expect(await dao.count(), 1);
      });
    });

    group('deleteAll', () {
      test('elimina todos los registros', () async {
        await dao.insertAll([_c(1, 'A', clave: 'C001')]);
        await dao.deleteAll();

        expect(await dao.count(), 0);
      });
    });
  });

  group('ProductoDao', () {
    late Database db;
    late ProductoDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createProductos);
      dao = ProductoDao(db);
    });

    tearDown(() => db.close());

    group('insertAll', () {
      test('inserta mÃºltiples productos', () async {
        await dao.insertAll([
          Producto(
            articuloId: 1,
            nombre: 'Producto A',
            clave: 'P001',
            precio: 10.0,
          ),
          Producto(
            articuloId: 2,
            nombre: 'Producto B',
            clave: 'P002',
            precio: 20.0,
          ),
        ]);

        expect(await dao.count(), 2);
      });
    });

    group('getFirst', () {
      test('retorna solo el lÃ­mite solicitado', () async {
        final productos = List.generate(
          10,
          (i) => Producto(
            articuloId: i + 1,
            nombre: 'P$i',
            clave: 'P${i + 1}',
            precio: (i + 1) * 10.0,
          ),
        );
        await dao.insertAll(productos);

        final first5 = await dao.getFirst(5);
        expect(first5.length, 5);
      });
    });

    group('search', () {
      test('retorna todos cuando query es null', () async {
        await dao.insertAll([
          Producto(articuloId: 1, nombre: 'A', clave: 'C001', precio: 10.0),
          Producto(articuloId: 2, nombre: 'B', clave: 'C002', precio: 20.0),
        ]);

        final result = await dao.search(null);
        expect(result.length, 2);
      });

      test('filtra por nombre', () async {
        await dao.insertAll([
          Producto(
            articuloId: 1,
            nombre: 'Chocolate',
            clave: 'CHO001',
            precio: 25.0,
          ),
          Producto(
            articuloId: 2,
            nombre: 'Galleta',
            clave: 'GAL001',
            precio: 10.0,
          ),
        ]);

        final result = await dao.search('Choco');
        expect(result.length, 1);
      });
    });

    group('getAll', () {
      test('retorna solo productos activos', () async {
        await dao.insertAll([
          Producto(
            articuloId: 1,
            nombre: 'Activo',
            clave: 'ACT001',
            precio: 10.0,
          ),
          Producto(
            articuloId: 2,
            nombre: 'Inactivo',
            clave: 'INA001',
            precio: 20.0,
            estatus: 'B',
          ),
        ]);

        final all = await dao.getAll();
        expect(all.length, 1);
        expect(all.first.nombre, 'Activo');
      });
    });

    group('deleteByIds', () {
      test('elimina solo los productos especificados por ID', () async {
        await dao.insertAll([
          Producto(articuloId: 1, nombre: 'P1', clave: 'P001', precio: 10.0),
          Producto(articuloId: 2, nombre: 'P2', clave: 'P002', precio: 20.0),
          Producto(articuloId: 3, nombre: 'P3', clave: 'P003', precio: 30.0),
        ]);
        await dao.deleteByIds([1, 2]);

        final remaining = await dao.getAll();
        expect(remaining.length, 1);
        expect(remaining.first.articuloId, 3);
      });
    });
  });

  group('VentaDao', () {
    late Database db;
    late VentaDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createVentasPendientes);
      dao = VentaDao(db);
    });

    tearDown(() => db.close());

    VentaPendiente venta({
      String id = 'VTA-001',
      int vendedorId = 1,
      double total = 100.0,
      String estado = 'pendiente',
      String fecha = '2026-07-28',
    }) => VentaPendiente(
      ventaMovilId: id,
      vendedorId: vendedorId,
      clienteId: 1,
      clienteNombre: 'Test',
      fechaHora: '${fecha}T10:00:00.000',
      total: total,
      estado: estado,
      detalles: [
        {'articulo_id': 1, 'unidades': 1, 'precio_unitario': total},
      ],
    );

    test('insert y getById', () async {
      final v = venta();
      await dao.insert(v);

      final found = await dao.getById('VTA-001');
      expect(found, isNotNull);
      expect(found!.total, 100.0);
    });

    test('getPendientes retorna solo pendientes', () async {
      await dao.insert(venta(id: 'VTA-001', estado: 'pendiente'));
      await dao.insert(venta(id: 'VTA-002', estado: 'enviada'));

      final pendientes = await dao.getPendientes();
      expect(pendientes.length, 1);
      expect(pendientes.first.ventaMovilId, 'VTA-001');
    });

    test('getByEstado con null retorna todos', () async {
      await dao.insert(venta(id: 'VTA-001'));
      await dao.insert(venta(id: 'VTA-002'));

      final all = await dao.getByEstado(null);
      expect(all.length, 2);
    });

    test('getByEstado con string vacÃ­o retorna todos', () async {
      await dao.insert(venta(id: 'VTA-001'));

      final all = await dao.getByEstado('');
      expect(all.length, 1);
    });

    test('getByEstado filtra correctamente', () async {
      await dao.insert(venta(id: 'VTA-001', estado: 'pendiente'));
      await dao.insert(venta(id: 'VTA-002', estado: 'enviada'));

      final enviadas = await dao.getByEstado('enviada');
      expect(enviadas.length, 1);
      expect(enviadas.first.ventaMovilId, 'VTA-002');
    });

    test('updateEstado con null no modifica nada', () async {
      await dao.insert(venta(id: 'VTA-001', estado: 'pendiente'));

      await dao.updateEstado('VTA-001', null);

      final v = await dao.getById('VTA-001');
      expect(v!.estado, 'pendiente');
    });

    test('updateEstado cambia el estado', () async {
      await dao.insert(venta(id: 'VTA-001', estado: 'pendiente'));

      await dao.updateEstado('VTA-001', 'enviada');

      final v = await dao.getById('VTA-001');
      expect(v!.estado, 'enviada');
    });

    test('updateAfterSync actualiza doctoPvId y folio', () async {
      await dao.insert(venta(id: 'VTA-001'));

      await dao.updateAfterSync(
        ventaMovilId: 'VTA-001',
        estado: 'enviada',
        doctoPvId: 12345,
        folio: 'V0000001',
      );

      final v = await dao.getById('VTA-001');
      expect(v!.estado, 'enviada');
      expect(v.doctoPvId, 12345);
      expect(v.folio, 'V0000001');
    });

    test('getDelDia con null retorna todos', () async {
      await dao.insert(venta(id: 'VTA-001'));
      await dao.insert(venta(id: 'VTA-002'));

      final result = await dao.getDelDia(null);
      expect(result.length, 2);
    });

    test('getDelDia filtra por fecha', () async {
      await dao.insert(venta(id: 'VTA-001', fecha: '2026-07-28'));
      await dao.insert(venta(id: 'VTA-002', fecha: '2026-07-29'));

      final result = await dao.getDelDia('2026-07-28');
      expect(result.length, 1);
    });

    test('getResumenDelDia retorna resumen correcto', () async {
      await dao.insert(venta(id: 'VTA-001', total: 100.0, estado: 'pendiente'));
      await dao.insert(venta(id: 'VTA-002', total: 200.0, estado: 'enviada'));

      final resumen = await dao.getResumenDelDia('2026-07-28');

      expect(resumen['total_ventas'], 2);
      expect((resumen['monto_total'] as num).toDouble(), 300.0);
      expect(resumen['pendientes'], 1);
      expect(resumen['enviadas'], 1);
    });

    test('deleteAll elimina todas las ventas', () async {
      await dao.insert(venta(id: 'VTA-001'));
      await dao.deleteAll();

      expect(await dao.getPendientes(), isEmpty);
    });
  });

  group('CobranzaDao', () {
    late Database db;
    late CobranzaDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createCobranzasPendientes);
      dao = CobranzaDao(db);
    });

    tearDown(() => db.close());

    test('insert y getById', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T10:00:00',
          totalCobrado: 500.0,
          pagos: [
            {'forma_cobro_id': 67, 'importe': 500.0},
          ],
          documentos: [
            {'docto_pv_original_id': 100, 'importe_pagado': 500.0},
          ],
        ),
      );

      final found = await dao.getById('COB-001');
      expect(found, isNotNull);
      expect(found!.totalCobrado, 500.0);
    });

    test('getPendientes retorna solo pendientes', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T10:00:00',
        ),
      );
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-002',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T11:00:00',
          totalCobrado: 0,
        ).copyWith(estado: 'enviada'),
      );

      final pendientes = await dao.getPendientes();
      expect(pendientes.length, 1);
      expect(pendientes.first.cobranzaMovilId, 'COB-001');
    });

    test('updateEstado cambia estado', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T10:00:00',
        ),
      );

      await dao.updateEstado('COB-001', 'enviada');

      final c = await dao.getById('COB-001');
      expect(c!.estado, 'enviada');
    });

    test('updateEstado con null no modifica', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T10:00:00',
        ),
      );

      await dao.updateEstado('COB-001', null);

      final c = await dao.getById('COB-001');
      expect(c!.estado, 'pendiente');
    });

    test('getDelDia con null retorna todos', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'A',
          fechaHora: '2026-07-28T10:00:00',
        ),
      );
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-002',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'B',
          fechaHora: '2026-07-29T10:00:00',
        ),
      );

      final result = await dao.getDelDia(null);
      expect(result.length, 2);
    });

    test('deleteAll elimina todo', () async {
      await dao.insert(
        CobranzaPendiente(
          cobranzaMovilId: 'COB-001',
          vendedorId: 1,
          clienteId: 1,
          clienteNombre: 'Test',
          fechaHora: '2026-07-28T10:00:00',
        ),
      );
      await dao.deleteAll();

      expect(await dao.getPendientes(), isEmpty);
    });
  });


  // =========================================================================
  // TESTS: Regresión para bug ""Solo 1 cliente visible con 90+ asignados""
  // =========================================================================

  group('ClienteDao - sin límite artificial', () {
    late Database db;
    late ClienteDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createClientes);
      dao = ClienteDao(db);
    });

    tearDown(() async => db.close());

    test('getAll() retorna TODOS los clientes sin límite', () async {
      final clientes = List<Cliente>.generate(
        110,
        (i) => Cliente(
          clienteId: i + 1,
          nombreCliente: 'Cliente ${i + 1}',
          clave: 'CL${i + 1}',
          telefono: '1234567890', poblacion: 'Test', tipoVenta: 1,
        ),
      );
      await dao.insertAll(clientes);

      final result = await dao.getAll();
      expect(result.length, equals(110));
    });

    test('getFirst(100) SÍ corta en 100 — confirmando que era el bug', () async {
      final clientes = List<Cliente>.generate(
        110,
        (i) => Cliente(
          clienteId: i + 1,
          nombreCliente: 'Cliente ${i + 1}',
          clave: 'CL${i + 1}',
          telefono: '1234567890', poblacion: 'Test', tipoVenta: 1,
        ),
      );
      await dao.insertAll(clientes);

      final result = await dao.getFirst(100);
      expect(result.length, equals(100));
    });
  });

  group('VentaDao.getDelDia() - solo ventas del día actual', () {
    late Database db;
    late VentaDao dao;

    setUp(() async {
      db = await _openDb();
      await db.execute(_createVentasPendientes);
      dao = VentaDao(db);
    });

    tearDown(() async => db.close());

    VentaPendiente makeVenta(int clienteId, String fecha) => VentaPendiente(
      ventaMovilId: 'vm-$clienteId-$fecha',
      vendedorId: 1,
      clienteId: clienteId,
      clienteNombre: 'Cliente $clienteId',
      fechaHora: '${fecha}T10:00:00',
      estado: 'pendiente',
      total: 100.0,
    );

    test('getDelDia() solo retorna ventas de la fecha indicada', () async {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final ayer = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      for (int i = 1; i <= 89; i++) {
        await dao.insert(makeVenta(i, ayer));
      }
      await dao.insert(makeVenta(90, hoy));
      await dao.insert(makeVenta(91, hoy));

      final result = await dao.getDelDia(hoy);
      expect(result.length, equals(2));
    });

    test('getDelDia() con fecha nula cae al getAll() (fallback defensivo)', () async {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      await dao.insert(makeVenta(1, hoy));
      await dao.insert(makeVenta(2, hoy));

      final result = await dao.getDelDia(null);
      expect(result.length, equals(2));
    });

    test('visitasMap construido con getDelDia() no contamina con ventas de ayer', () async {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final ayer = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      for (int i = 1; i <= 89; i++) {
        await dao.insert(makeVenta(i, ayer));
      }
      await dao.insert(makeVenta(90, hoy));

      final ventasHoy = await dao.getDelDia(hoy);
      final Map<int, VentaPendiente> visitasMap = {
        for (final v in ventasHoy) v.clienteId: v,
      };

      expect(visitasMap.containsKey(90), isTrue);
      for (int i = 1; i <= 89; i++) {
        expect(visitasMap.containsKey(i), isFalse);
      }
    });
  });
}


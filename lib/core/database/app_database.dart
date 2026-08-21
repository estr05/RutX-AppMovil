import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'daos/cliente_dao.dart';
import 'daos/producto_dao.dart';
import 'daos/venta_dao.dart';
import 'daos/notificacion_dao.dart';
import 'entities/notificacion_entity.dart';
import 'entities/causa_no_venta_entity.dart';
import 'daos/causa_no_venta_dao.dart';
import 'daos/cobranza_dao.dart';
import 'daos/emisor_dao.dart';
import 'daos/sucursal_dao.dart';
import 'daos/cola_sincronizacion_dao.dart';
import 'daos/folio_local_dao.dart';
import 'entities/forma_cobro_entity.dart';
import 'daos/forma_cobro_dao.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;
  AppDatabase._();

  Database? _database;
  ClienteDao? _clienteDao;
  ProductoDao? _productDao;
  VentaDao? _ventaDao;
  NotificacionDao? _notificacionDao;
  CausaNoVentaDao? _causaNoVentaDao;
  CobranzaDao? _cobranzaDao;
  EmisorDao? _emisorDao;
  SucursalDao? _sucursalDao;
  ColaSincronizacionDao? _colaDao;
  FolioLocalDao? _folioLocalDao;
  FormaCobroDao? _formaCobroDao;

  ClienteDao get clienteDao {
    if (_clienteDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _clienteDao!;
  }

  ProductoDao get productDao {
    if (_productDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _productDao!;
  }

  VentaDao get ventaDao {
    if (_ventaDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _ventaDao!;
  }

  NotificacionDao get notificacionDao {
    if (_notificacionDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _notificacionDao!;
  }

  CausaNoVentaDao get causaNoVentaDao {
    if (_causaNoVentaDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _causaNoVentaDao!;
  }

  CobranzaDao get cobranzaDao {
    if (_cobranzaDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _cobranzaDao!;
  }

  EmisorDao get emisorDao {
    if (_emisorDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _emisorDao!;
  }

  SucursalDao get sucursalDao {
    if (_sucursalDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _sucursalDao!;
  }

  ColaSincronizacionDao get colaDao {
    if (_colaDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _colaDao!;
  }

  FolioLocalDao get folioLocalDao {
    if (_folioLocalDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _folioLocalDao!;
  }

  FormaCobroDao get formaCobroDao {
    if (_formaCobroDao == null) {
      throw StateError('AppDatabase not initialized. Call initialize() first.');
    }
    return _formaCobroDao!;
  }

  static const int _version = 17;
  static const String _dbName = 'rutx_movil.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migración incremental para preservar datos existentes
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN forma_cobro_id INTEGER DEFAULT 67',
      );
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN caja_id INTEGER',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN docto_pv_id INTEGER',
      );
      await db.execute('ALTER TABLE ventas_pendientes ADD COLUMN folio TEXT');
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN porcentaje_impuesto INTEGER DEFAULT 16',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN impuesto_id INTEGER DEFAULT 622',
      );
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE clientes ADD COLUMN clave TEXT DEFAULT ""');
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN telefono TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN poblacion TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN saldo REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE clientes ADD COLUMN tipo_venta INTEGER DEFAULT 1',
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE causas_no_venta (
          causa_id INTEGER PRIMARY KEY,
          descripcion TEXT NOT NULL,
          estatus TEXT DEFAULT 'A'
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN existencias_gral REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN existencias REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN peso REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN merma REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE productos ADD COLUMN permite_merma TEXT DEFAULT "No"',
      );
    }
    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN pagos_json TEXT',
      );
    }
    if (oldVersion < 11) {
      await db.execute('''
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
      ''');
    }
    // Version 12: Agregar tablas de datos fiscales del emisor y sucursal
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE emisor (
          id INTEGER PRIMARY KEY,
          rfc TEXT NOT NULL DEFAULT '',
          nombre_fiscal TEXT NOT NULL DEFAULT '',
          domicilio_fiscal TEXT NOT NULL DEFAULT '',
          regimen_fiscal TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.execute('''
        CREATE TABLE sucursal (
          id INTEGER PRIMARY KEY,
          sucursal_id INTEGER NOT NULL DEFAULT 0,
          nombre TEXT NOT NULL DEFAULT '',
          calle TEXT NOT NULL DEFAULT '',
          num_exterior TEXT NOT NULL DEFAULT '',
          num_interior TEXT NOT NULL DEFAULT '',
          colonia TEXT NOT NULL DEFAULT '',
          poblacion TEXT NOT NULL DEFAULT '',
          codigo_postal TEXT NOT NULL DEFAULT '',
          telefono TEXT NOT NULL DEFAULT ''
        )
      ''');
      // Agregar columna RFC a la tabla clientes (para futuros CFDIs)
      try {
        await db.execute('ALTER TABLE clientes ADD COLUMN cliente_rfc TEXT');
      } catch (e) {
        // Ignorar si ya existe
      }
    }
    // Version 13: Asegurar que los cambios de la version 12 se apliquen a bases de datos que se crearon directamente en v12 sin onUpgrade
    if (oldVersion < 13) {
      try {
        await db.execute('ALTER TABLE clientes ADD COLUMN cliente_rfc TEXT');
      } catch (e) {
        // Ignorar si ya existe
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS emisor (
          id INTEGER PRIMARY KEY,
          rfc TEXT NOT NULL DEFAULT '',
          nombre_fiscal TEXT NOT NULL DEFAULT '',
          domicilio_fiscal TEXT NOT NULL DEFAULT '',
          regimen_fiscal TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sucursal (
          id INTEGER PRIMARY KEY,
          sucursal_id INTEGER NOT NULL DEFAULT 0,
          nombre TEXT NOT NULL DEFAULT '',
          calle TEXT NOT NULL DEFAULT '',
          num_exterior TEXT NOT NULL DEFAULT '',
          num_interior TEXT NOT NULL DEFAULT '',
          colonia TEXT NOT NULL DEFAULT '',
          poblacion TEXT NOT NULL DEFAULT '',
          codigo_postal TEXT NOT NULL DEFAULT '',
          telefono TEXT NOT NULL DEFAULT ''
        )
      ''');
    }
    // Version 14: Cola de sincronizacion centralizada con orden de envio
    if (oldVersion < 14) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cola_sincronizacion (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          entidad_id TEXT NOT NULL,
          estado TEXT DEFAULT 'pendiente',
          prioridad INTEGER DEFAULT 0,
          creado_en TEXT NOT NULL,
          sincronizado_en TEXT,
          reintentos INTEGER DEFAULT 0,
          ultimo_error TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cola_estado ON cola_sincronizacion(estado)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cola_tipo_entidad ON cola_sincronizacion(tipo, entidad_id)',
      );
      // Migrar registros pendientes existentes a la cola
      await db.rawInsert('''
        INSERT OR IGNORE INTO cola_sincronizacion (tipo, entidad_id, estado, creado_en)
        SELECT 'venta', venta_movil_id, 'pendiente', fecha_hora
        FROM ventas_pendientes WHERE estado = 'pendiente'
      ''');
      await db.rawInsert('''
        INSERT OR IGNORE INTO cola_sincronizacion (tipo, entidad_id, estado, creado_en)
        SELECT 'cobranza', cobranza_movil_id, 'pendiente', fecha_hora
        FROM cobranzas_pendientes WHERE estado = 'pendiente'
      ''');
    }
    // Version 15: Impuestos compuestos + precio con impuesto en el catalogo,
    //              identidad completa en las ventas pendientes
    if (oldVersion < 15) {
      await db.execute(
        'ALTER TABLE productos ADD COLUMN precio_con_impuesto REAL DEFAULT 0.0',
      );
      await db.execute('ALTER TABLE productos ADD COLUMN impuestos_json TEXT');
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN cajero_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN almacen_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN sucursal_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN usuario_creador TEXT',
      );
    }
    // Version 16: Folios provisionales offline (folios_locales) + referencia
    // local en cada venta pendiente
    if (oldVersion < 16) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folios_locales (
          cajero_id INTEGER PRIMARY KEY,
          consecutivo INTEGER NOT NULL DEFAULT 0,
          actualizado_en TEXT
        )
      ''');
      await db.execute(
        'ALTER TABLE ventas_pendientes ADD COLUMN folio_local TEXT',
      );
    }
    // Version 17: Catálogo dinámico de Formas de Cobro (formas_cobro)
    if (oldVersion < 17) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS formas_cobro (
          forma_cobro_id INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL DEFAULT 'C',
          estatus TEXT DEFAULT 'A'
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE TABLE notificaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mensaje TEXT NOT NULL,
        leida INTEGER DEFAULT 0,
        fecha_creacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE causas_no_venta (
        causa_id INTEGER PRIMARY KEY,
        descripcion TEXT NOT NULL,
        estatus TEXT DEFAULT 'A'
      )
    ''');
    await db.execute('''
      CREATE TABLE formas_cobro (
        forma_cobro_id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'C',
        estatus TEXT DEFAULT 'A'
      )
    ''');
    await db.execute('''
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
    ''');

    // Datos fiscales del emisor (RFC, razon social)
    await db.execute('''
      CREATE TABLE emisor (
        id INTEGER PRIMARY KEY,
        rfc TEXT NOT NULL DEFAULT '',
        nombre_fiscal TEXT NOT NULL DEFAULT '',
        domicilio_fiscal TEXT NOT NULL DEFAULT '',
        regimen_fiscal TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Datos del establecimiento (sucursal)
    await db.execute('''
      CREATE TABLE sucursal (
        id INTEGER PRIMARY KEY,
        sucursal_id INTEGER NOT NULL DEFAULT 0,
        nombre TEXT NOT NULL DEFAULT '',
        calle TEXT NOT NULL DEFAULT '',
        num_exterior TEXT NOT NULL DEFAULT '',
        num_interior TEXT NOT NULL DEFAULT '',
        colonia TEXT NOT NULL DEFAULT '',
        poblacion TEXT NOT NULL DEFAULT '',
        codigo_postal TEXT NOT NULL DEFAULT '',
        telefono TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Cola de sincronizacion centralizada
    await db.execute('''
      CREATE TABLE cola_sincronizacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        entidad_id TEXT NOT NULL,
        estado TEXT DEFAULT 'pendiente',
        prioridad INTEGER DEFAULT 0,
        creado_en TEXT NOT NULL,
        sincronizado_en TEXT,
        reintentos INTEGER DEFAULT 0,
        ultimo_error TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cola_estado ON cola_sincronizacion(estado)',
    );
    await db.execute(
      'CREATE INDEX idx_cola_tipo_entidad ON cola_sincronizacion(tipo, entidad_id)',
    );

    // Folios provisionales offline (uno por cajero)
    await db.execute('''
      CREATE TABLE folios_locales (
        cajero_id INTEGER PRIMARY KEY,
        consecutivo INTEGER NOT NULL DEFAULT 0,
        actualizado_en TEXT
      )
    ''');
  }

  Future<void> initialize() async {
    if (_database != null) return;
    final db = await database;
    _clienteDao = ClienteDao(db);
    _productDao = ProductoDao(db);
    _ventaDao = VentaDao(db);
    _notificacionDao = NotificacionDao(db);
    _causaNoVentaDao = CausaNoVentaDao(db);
    _cobranzaDao = CobranzaDao(db);
    _emisorDao = EmisorDao(db);
    _sucursalDao = SucursalDao(db);
    _colaDao = ColaSincronizacionDao(db);
    _folioLocalDao = FolioLocalDao(db);
    _formaCobroDao = FormaCobroDao(db);

    // Auto-seed ONLY if no clients exist (sync will provide real data)
    final clientesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM clientes'),
        ) ??
        0;
    if (clientesCount == 0) {
      await seedDatabase();
    } else {
      // Ensure local-only tables like causas_no_venta are seeded even if clients were synced
      final causasCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM causas_no_venta'),
          ) ??
          0;
      if (causasCount == 0) {
        await causaNoVentaDao.insertAll(CausaNoVenta.causasSemilla);
      }
    }
  }

  Future<void> seedDatabase() async {
    // 1. Notificaciones
    await notificacionDao.insertAll([
      Notificacion(
        mensaje: 'Promoción refrescos hoy|Oficina Central|08:00|Confirmado',
        leida: true,
        fechaCreacion: '2026-07-02 08:00:00',
      ),
      Notificacion(
        mensaje: 'Meta del día actualizada|Gerente de Ventas|09:30|',
        leida: true,
        fechaCreacion: '2026-07-02 09:30:00',
      ),
      Notificacion(
        mensaje: 'Producto sin stock: Refresco Naranja 600ml|Almacén|10:15|',
        leida: false,
        fechaCreacion: '2026-07-02 10:15:00',
      ),
      Notificacion(
        mensaje:
            'Recordatorio de cierre obligatorio de jornada|Oficina Central|14:00|',
        leida: false,
        fechaCreacion: '2026-07-02 14:00:00',
      ),
      Notificacion(
        mensaje:
            'Aviso: Actualización obligatoria de precios de gasolina|Administración|11:00|',
        leida: true,
        fechaCreacion: '2026-07-02 11:00:00',
      ),
      Notificacion(
        mensaje:
            'Reunión de urgencia con equipo de ventas a las 16:00|Dirección General|13:00|',
        leida: false,
        fechaCreacion: '2026-07-02 13:00:00',
      ),
      Notificacion(
        mensaje:
            'Nueva ruta asignada para mañana: Sector Norte|Logística|12:30|Confirmado',
        leida: true,
        fechaCreacion: '2026-07-02 12:30:00',
      ),
      Notificacion(
        mensaje:
            'Bono mensual por efectividad liberado|Recursos Humanos|09:00|Confirmado',
        leida: true,
        fechaCreacion: '2026-07-02 09:00:00',
      ),
    ]);

    // 4. Causas de No Venta (Semilla local predeterminada)
    await causaNoVentaDao.insertAll(CausaNoVenta.causasSemilla);
  }

  Future<void> limpiarDatosDelDia() async {
    await clienteDao.deleteAll();
    await productDao.deleteAll();
    await ventaDao.deleteAll();
    await cobranzaDao.deleteAll();
    await notificacionDao.deleteAll();
    await emisorDao.delete();
    await sucursalDao.delete();
    await colaDao.limpiarTodo();
    // No eliminamos causaNoVentaDao porque son predeterminadas y no se sincronizan
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

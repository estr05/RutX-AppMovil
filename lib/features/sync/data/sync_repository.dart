import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/entities/cliente_entity.dart';
import '../../../core/database/entities/producto_entity.dart';
import '../../../core/database/entities/emisor_entity.dart';
import '../../../core/database/entities/sucursal_entity.dart';
import '../../../core/network/sync_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/connection_state_service.dart';

class SyncRepository {
  final Dio _dio;
  final AppDatabase _db;

  SyncRepository({Dio? dio, AppDatabase? db})
      : _dio = dio ?? DioClient().dio,
        _db = db ?? AppDatabase();

  Future<SyncResult> downloadMorningData(int vendedorId) async {
    if (ConnectionStateService().isOffline) {
      return SyncFailure(
        mensaje: 'Sin conexión al servidor. Verifica tu conexión a internet.',
        intentos: 0,
      );
    }
    const maxIntentos = 3;
    String lastErrorMsg = 'No se pudo completar la sincronizacion. Verifica tu conexion.';

    for (int intento = 1; intento <= maxIntentos; intento++) {
      try {
        // La identidad (vendedor, caja, almacen) viaja en el token JWT
        final response = await _dio.get('/api/v1/routes/sync');
        if (response.statusCode == 200 && response.data != null) {
          return await _procesarRespuestaRuta(response.data);
        } else {
          lastErrorMsg = 'Error del servidor (${response.statusCode}).';
        }
      } on DioException catch (e) {
        lastErrorMsg = _mensajeError(e);
        if (_esErrorNoReintentable(e)) {
          return SyncFailure(mensaje: lastErrorMsg, intentos: intento);
        }
        if (intento < maxIntentos) await _esperar(intento);
      } catch (e) {
        lastErrorMsg = 'Error inesperado: $e';
      }
    }

    return SyncFailure(
      mensaje: lastErrorMsg,
      intentos: maxIntentos,
    );
  }

  int _contarCreditos(List<Cliente> clientes) =>
      clientes.where((c) => c.tipoVenta > 1).length;

  Future<SyncResult> _procesarRespuestaRuta(dynamic data) async =>
      _procesarClientesYProductos(data, 'Ruta');

  /// Parsea la respuesta del servidor sin tocar la base de datos.
  DatosServidor _parsearDatosServidor(dynamic data) {
    final List<dynamic> clientesJson = data['clientes'] ?? [];
    final List<dynamic> productosJson = data['productos'] ?? [];

    final clientes = clientesJson.map((json) => Cliente(
          clienteId: json['cliente_id'] as int,
          clave: json['clave'] as String? ?? '',
          nombreCliente: json['nombre_cliente'] as String,
          telefono: json['telefono'] as String? ?? '',
          calle: json['calle'] as String?,
          colonia: json['colonia'] as String?,
          poblacion: json['poblacion'] as String? ?? '',
          codigoPostal: json['codigo_postal'] as String?,
          limiteCredito: (json['limite_credito'] as num?)?.toDouble() ?? 0.0,
          saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
          tipoVenta: json['cond_pago_id'] as int? ?? 1,
          rfc: json['rfc'] as String?,
        )).toList();

    final productos = productosJson.map((json) {
      final id = json['articulo_id'] as int;
      final clave = json['clave'] as String? ?? id.toString();
      final precio = (json['precio'] as num?)?.toDouble();
      if (precio == null) return null;

      final impuestosJson = json['impuestos'] as List<dynamic>? ?? const [];
      final impuestos = impuestosJson.map((i) {
        final m = i as Map<String, dynamic>;
        return ImpuestoProducto(
          impuestoId: m['impuesto_id'] as int,
          pctjeImpuesto: (m['pctje_impuesto'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final impuestoPrincipal = impuestos.isNotEmpty
          ? impuestos.first
          : ImpuestoProducto(
              impuestoId: json['impuesto_id'] as int? ?? 622,
              pctjeImpuesto: (json['porcentaje_impuesto'] as num?)?.toDouble() ?? 16.0,
            );

      return Producto(
        articuloId: id,
        nombre: json['nombre'] as String,
        estatus: json['estatus'] as String? ?? 'A',
        clave: clave,
        precio: precio,
        precioConImpuesto: (json['precio_con_impuesto'] as num?)?.toDouble() ?? 0.0,
        porcentajeImpuesto: impuestoPrincipal.pctjeImpuesto.round(),
        impuestoId: impuestoPrincipal.impuestoId,
        impuestos: impuestos,
        existencias: (json['existencias'] as num?)?.toDouble() ?? 0.0,
      );
    }).whereType<Producto>().toList();

    final emisorJson = data['emisor'] as Map<String, dynamic>?;
    final sucursalJson = data['sucursal'] as Map<String, dynamic>?;

    return DatosServidor(
      clientes: clientes,
      productos: productos,
      emisor: emisorJson != null ? Emisor.fromJson(emisorJson) : null,
      sucursal: sucursalJson != null ? Sucursal.fromJson(sucursalJson) : null,
    );
  }

  /// Etapa 1: consulta el catálogo del servidor y lo compara con lo que ya hay
  /// en el equipo, sin modificar nada. Retorna el análisis para la descarga
  /// incremental (solo los datos faltantes).
  Future<AnalisisDescarga> analizarDescarga() async {
    if (ConnectionStateService().isOffline) {
      throw StateError('Sin conexión al servidor. Conéctate a una red e intenta nuevamente.');
    }
    const maxIntentos = 2;
    Object lastError = StateError('No se pudo completar el análisis.');

    for (int intento = 1; intento <= maxIntentos; intento++) {
      try {
        final response = await _dio.get('/api/v1/routes/sync');
        if (response.statusCode == 200 && response.data != null) {
          final datos = _parsearDatosServidor(response.data);
          final idsClientesLocales = await _db.clienteDao.getAllIds();
          final idsProductosLocales = await _db.productDao.getAllIds();

          final idsClientesServidor = datos.clientes.map((c) => c.clienteId).toSet();
          final idsProductosServidor = datos.productos.map((p) => p.articuloId).toSet();

          final clientesNuevos = datos.clientes
              .where((c) => !idsClientesLocales.contains(c.clienteId))
              .toList();
          final productosNuevos = datos.productos
              .where((p) => !idsProductosLocales.contains(p.articuloId))
              .toList();

          final clientesRemovidos = idsClientesLocales
              .where((id) => !idsClientesServidor.contains(id))
              .toList();
          final productosRemovidos = idsProductosLocales
              .where((id) => !idsProductosServidor.contains(id))
              .toList();

          return AnalisisDescarga(
            clientesServidor: datos.clientes,
            productosServidor: datos.productos,
            emisor: datos.emisor,
            sucursal: datos.sucursal,
            clientesLocales: idsClientesLocales.length,
            productosLocales: idsProductosLocales.length,
            clientesNuevos: clientesNuevos,
            productosNuevos: productosNuevos,
            clientesRemovidos: clientesRemovidos,
            productosRemovidos: productosRemovidos,
          );
        }
        lastError = StateError('Error del servidor (${response.statusCode}).');
      } on DioException catch (e) {
        lastError = StateError(_mensajeError(e));
        if (_esErrorNoReintentable(e)) break;
      } catch (e) {
        lastError = StateError('Error al analizar datos: $e');
        break;
      }
      if (intento < maxIntentos) await _esperar(intento);
    }

    throw lastError;
  }

  /// Etapa 2: actualiza catálogos con los datos vigentes del servidor y elimina
  /// aquellos clientes o productos que hayan sido desasignados o removidos.
  /// No limpia ventas ni duplica registros.
  Future<SyncResult> aplicarDescargaIncremental(AnalisisDescarga analisis) async {
    try {
      // 1. Insertar / Actualizar catálogos del servidor (con últimos precios, saldos, límites)
      await _db.clienteDao.insertAll(analisis.clientesServidor);
      await _db.productDao.insertAll(analisis.productosServidor);

      // 2. Eliminar registros locales que ya no están asignados en el servidor
      if (analisis.clientesRemovidos.isNotEmpty) {
        await _db.clienteDao.deleteByIds(analisis.clientesRemovidos);
      }
      if (analisis.productosRemovidos.isNotEmpty) {
        await _db.productDao.deleteByIds(analisis.productosRemovidos);
      }

      // 3. Re-aplicar el descuento de ventas aún no sincronizadas ('pendiente'):
      //    el stock del servidor no las conoce todavía, y sin este paso el
      //    stock local "regresaría" permitiendo sobreventa offline.
      try {
        await _db.ventaDao.reaplicarExistenciasPendientes();
      } catch (e) {
        debugPrint('[Sync] Error al reaplicar existencias pendientes: $e');
      }

      // 3. Emisor y sucursal
      if (analisis.emisor != null) {
        await _db.emisorDao.insert(analisis.emisor!);
      }
      if (analisis.sucursal != null) {
        await _db.sucursalDao.insert(analisis.sucursal!);
      }

      return SyncSuccess(
        clientes: analisis.clientesServidor.length,
        productos: analisis.productosServidor.length,
        credito: _contarCreditos(analisis.clientesServidor),
      );
    } catch (e) {
      return SyncFailure(mensaje: 'Error al actualizar datos: $e', intentos: 1);
    }
  }

  Future<SyncResult> _procesarClientesYProductos(dynamic data, String origen) async {
    try {
      final datos = _parsearDatosServidor(data);
      final clientes = datos.clientes;
      final productos = datos.productos;
      final creditos = _contarCreditos(clientes);

      try { await _db.limpiarDatosDelDia(); } catch (e) { debugPrint('[Sync] Error al limpiar: $e'); }

      try {
        await _db.clienteDao.insertAll(clientes);
      } catch (e) {
        return SyncFailure(mensaje: 'Error SQLite clientes: $e', intentos: 3);
      }

      try {
        await _db.productDao.insertAll(productos);
      } catch (e) {
        return SyncFailure(mensaje: 'Error SQLite productos: $e', intentos: 3);
      }

      // Re-aplicar el descuento de ventas pendientes (defensivo: en el sync
      // completo se limpian las ventas, pero si alguna quedó pendiente el
      // stock local no debe "regresar").
      try {
        await _db.ventaDao.reaplicarExistenciasPendientes();
      } catch (e) {
        debugPrint('[Sync] Error al reaplicar existencias pendientes: $e');
      }

      if (datos.emisor != null) {
        try { await _db.emisorDao.insert(datos.emisor!); } catch (e) {}
      }

      if (datos.sucursal != null) {
        try { await _db.sucursalDao.insert(datos.sucursal!); } catch (e) {}
      }

      return SyncSuccess(
        clientes: clientes.length,
        productos: productos.length,
        credito: creditos,
      );
    } catch (e) {
      return SyncFailure(
        mensaje: 'Error de parseo: $e',
        intentos: 3,
      );
    }
  }

  bool _esErrorNoReintentable(DioException e) {
    return e.response != null && e.response!.statusCode == 401;
  }

  String _mensajeError(DioException e) {
    if (e.response != null) {
      final codigo = e.response!.statusCode;
      if (codigo == 401) return 'Sesión expirada. Inicia sesión de nuevo.';
      if (codigo == 404) return 'Ruta no encontrada para este vendedor.';
      return 'Error del servidor ($codigo).';
    }
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'El servidor no respondió a tiempo.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sin conexión al servidor. Verifica tu conexión.';
    }
    return 'Error de conexión.';
  }

  Future<void> _esperar(int intento) async {
    final segundos = [2, 4, 8][intento - 1];
    await Future.delayed(Duration(seconds: segundos));
  }
}

/// Catálogo completo tal como lo envía el servidor (sin tocar la base).
class DatosServidor {
  final List<Cliente> clientes;
  final List<Producto> productos;
  final Emisor? emisor;
  final Sucursal? sucursal;

  DatosServidor({
    required this.clientes,
    required this.productos,
    this.emisor,
    this.sucursal,
  });
}

/// Resultado de la etapa 1 (análisis): compara el servidor contra lo local
/// y determina exactamente qué falta por descargar.
class AnalisisDescarga {
  final List<Cliente> clientesServidor;
  final List<Producto> productosServidor;
  final Emisor? emisor;
  final Sucursal? sucursal;

  final int clientesLocales;
  final int productosLocales;
  final List<Cliente> clientesNuevos;
  final List<Producto> productosNuevos;
  final List<int> clientesRemovidos;
  final List<int> productosRemovidos;

  AnalisisDescarga({
    required this.clientesServidor,
    required this.productosServidor,
    this.emisor,
    this.sucursal,
    required this.clientesLocales,
    required this.productosLocales,
    required this.clientesNuevos,
    required this.productosNuevos,
    required this.clientesRemovidos,
    required this.productosRemovidos,
  });

  int get clientesServidorCount => clientesServidor.length;
  int get productosServidorCount => productosServidor.length;
  int get clientesNuevosCount => clientesNuevos.length;
  int get productosNuevosCount => productosNuevos.length;
  int get clientesRemovidosCount => clientesRemovidos.length;
  int get productosRemovidosCount => productosRemovidos.length;

  int get totalNuevos => clientesNuevosCount + productosNuevosCount;
  int get totalRemovidos => clientesRemovidosCount + productosRemovidosCount;
  int get totalCambios => totalNuevos + totalRemovidos;
  int get creditosServidor =>
      clientesServidor.where((c) => c.tipoVenta > 1).length;

  bool get estaAlDia => totalCambios == 0;
}


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/entities/venta_pendiente_entity.dart';
import '../../../core/network/connection_state_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/sync_result.dart';
import '../../../core/network/sync_queue_processor.dart';

class SalesRepository {
  static final SalesRepository _instance = SalesRepository._();
  factory SalesRepository() => _instance;
  SalesRepository._();

  final DioClient _dioClient = DioClient();

  /// Asigna un folio provisional consecutivo (PRV-0000001) a la venta.
  /// Siempre se genera (funciona como referencia local); si la sincronización
  /// tiene éxito, el folio real de Microsip toma precedencia en pantalla.
  Future<VentaPendiente> _asignarFolioLocal(VentaPendiente venta) async {
    if (venta.folioLocal != null && venta.folioLocal!.isNotEmpty) return venta;
    try {
      final db = AppDatabase();
      await db.initialize();
      final folioLocal = await db.folioLocalDao.siguienteFolioProvisional(
        venta.cajeroId ?? 0,
      );
      return venta.copyWith(folioLocal: folioLocal);
    } catch (e) {
      debugPrint('[FolioLocal] Error al generar folio provisional: $e');
      return venta;
    }
  }

  Future<bool> saveSaleLocally(VentaPendiente venta) async {
    try {
      final conFolio = await _asignarFolioLocal(venta);
      final db = AppDatabase();
      await db.initialize();
      // Transacción atómica: guardar la venta + descontar existencias del
      // almacén. Retorna false si no hay existencia suficiente (rollback).
      return await db.ventaDao.insertDescontandoExistencia(conFolio);
    } catch (e) {
      return false;
    }
  }

  /// Guarda localmente, encola y si hay conexion sube al servidor inmediatamente.
  /// Siempre retorna un mapa (para mostrar el folio provisional PRV-xxxxxxx):
  ///   - 'success': true si la venta quedo registrada en Microsip
  ///   - 'docto_pv_id' / 'folio': folio real cuando success == true
  ///   - 'folio_local': folio provisional offline (siempre disponible)
  Future<Map<String, dynamic>?> saveAndSyncSale(VentaPendiente venta) async {
    try {
      final conFolio = await _asignarFolioLocal(venta);
      final db = AppDatabase();
      await db.initialize();
      // Transacción atómica: guardar la venta + descontar existencias del
      // almacén. Si algún artículo no tiene existencia suficiente, no se
      // guarda nada (retorna null) aunque la app esté offline.
      final guardada = await db.ventaDao.insertDescontandoExistencia(conFolio);
      if (!guardada) return null;

      final queue = SyncQueueProcessor(db: db);
      await queue.enqueue('venta', conFolio.ventaMovilId);

      if (ConnectionStateService().currentState ==
          RutxConnectionState.offline) {
        await ConnectionStateService().forceCheck();
        if (ConnectionStateService().currentState ==
            RutxConnectionState.offline) {
          return {'success': false, 'folio_local': conFolio.folioLocal};
        }
      }

      final result = await uploadOne(conFolio.ventaMovilId);
      if (result['success'] == true) {
        await queue.markCompleted('venta', conFolio.ventaMovilId);
        return {
          'success': true,
          'docto_pv_id': result['docto_pv_id'],
          'folio': result['folio'],
          'folio_local': conFolio.folioLocal,
        };
      }
      return {'success': false, 'folio_local': conFolio.folioLocal};
    } catch (e) {
      debugPrint('[saveAndSyncSale] Error crítico: $e');
      return {
        'success': false,
        'error': 'save_failed',
        'mensaje': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> uploadOne(String ventaMovilId) async {
    if (ConnectionStateService().currentState == RutxConnectionState.offline) {
      await ConnectionStateService().forceCheck();
      if (ConnectionStateService().currentState ==
          RutxConnectionState.offline) {
        return {'success': false, 'error': 'offline'};
      }
    }
    try {
      final db = AppDatabase();
      await db.initialize();
      final venta = await db.ventaDao.getById(ventaMovilId);
      if (venta == null) {
        return {'success': false, 'error': 'venta_no_encontrada'};
      }

      final result = await _uploadSale(venta);
      if (result != null && result['success'] == true) {
        await db.ventaDao.updateAfterSync(
          ventaMovilId: ventaMovilId,
          estado: 'enviada',
          doctoPvId: result['docto_pv_id'] as int?,
          folio: result['folio'] as String?,
        );
        return result;
      }
      if (result != null &&
          _esSesionCaducada(result['error']?.toString() ?? '')) {
        await _dioClient.cerrarSesionPorCaducidad();
      }
      return result ?? {'success': false, 'error': 'respuesta_vacia'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<SyncResult> syncPendingSales() async {
    if (ConnectionStateService().currentState !=
        RutxConnectionState.connected) {
      return SyncFailure(mensaje: 'Sin conexión');
    }

    try {
      final db = AppDatabase();
      await db.initialize();
      final pendientes = await db.ventaDao.getPendientes();
      final errores = await db.ventaDao.getByEstado('error');
      final todas = [...pendientes, ...errores];

      if (todas.isEmpty) return SyncSuccess(clientes: 0, productos: 0);

      int enviadas = 0;
      String? ultimoError;
      bool sesionCaducada = false;

      for (final v in todas) {
        final result = await _uploadSaleWithRetry(v);
        if (result['success'] == true) {
          // Si la venta venía de 'error' su stock se había revertido;
          // al reenviarse con éxito, las unidades sí salen del almacén
          // y se vuelven a descontar.
          if (v.estado == 'error') {
            await db.ventaDao.descontarExistencias(v);
          }
          await db.ventaDao.updateAfterSync(
            ventaMovilId: v.ventaMovilId,
            estado: 'enviada',
            doctoPvId: result['docto_pv_id'] as int?,
            folio: result['folio'] as String?,
          );
          enviadas++;
        } else {
          ultimoError = result['error'] as String? ?? 'Error desconocido';

          if (_esSesionCaducada(ultimoError)) {
            // El servidor rechazó el token: no es un error de la venta,
            // es sesión caducada. No marcar 'error' para no bloquearla.
            sesionCaducada = true;
            await db.ventaDao.updateEstado(v.ventaMovilId, 'pendiente');
          } else if (!_esReintentable(ultimoError)) {
            // Rechazo definitivo del servidor: la venta nunca salió del
            // almacén real, así que se revierten las existencias locales
            // que se descontaron al confirmarla.
            await db.ventaDao.marcarErrorRevertirExistencia(v);
          } else {
            await db.ventaDao.updateEstado(v.ventaMovilId, 'pendiente');
          }
        }
      }

      if (sesionCaducada) {
        await _dioClient.cerrarSesionPorCaducidad();
        return SyncFailure(
          mensaje:
              'Tu sesión ha caducado. Inicia sesión de nuevo para sincronizar.',
        );
      }

      if (ultimoError != null && enviadas == 0) {
        return SyncFailure(
          mensaje:
              _esReintentable(ultimoError)
                  ? 'Sin conexión al servidor (Network Error)'
                  : ultimoError,
        );
      }
      return SyncSuccess(clientes: 0, productos: enviadas);
    } catch (e) {
      return SyncFailure(mensaje: e.toString());
    }
  }

  /// Indica si el error proviene de un token JWT rechazado por el servidor
  /// (401). No es un error de la venta: es una sesión caducada o inválida.
  bool _esSesionCaducada(String error) {
    final match = RegExp(
      r'api error \[(\d{3})\]',
      caseSensitive: false,
    ).firstMatch(error);
    return match != null && match.group(1) == '401';
  }

  /// Determina si un error justifica reintentar la venta (estado 'pendiente')
  /// o marcarla como error definitivo.
  ///
  /// Son reintentables: errores de red/timeout (sin respuesta), 5xx (servidor
  /// ocupado o deadlock transitorio 503) y 409 (la venta ya esta en proceso
  /// en otro sincronizador; se reintentara mas tarde).
  bool _esReintentable(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('network is unreachable') ||
        error == 'Error desconocido') {
      return true;
    }
    final match = RegExp(
      r'api error \[(\d{3})\]',
      caseSensitive: false,
    ).firstMatch(error);
    if (match != null) {
      final code = int.tryParse(match.group(1) ?? '') ?? 0;
      if (code >= 500 || code == 409) return true;
    }
    return false;
  }

  /// Retorna un mapa con success, docto_pv_id, folio
  /// No reintenta errores 4xx (rechazo del servidor)
  Future<Map<String, dynamic>> _uploadSaleWithRetry(VentaPendiente v) async {
    const maxRetries = 2;
    const delays = [Duration(seconds: 1)];

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await _uploadSale(v);
        if (result != null) return result;
      } catch (e) {
        final msg = e.toString();
        // Si el servidor rechazó la petición (4xx), no reintentar
        if (msg.contains('API ERROR [4') || msg.contains('status code 4')) {
          return {'success': false, 'error': msg};
        }
        if (attempt == maxRetries - 1) {
          return {'success': false, 'error': msg};
        }
      }
      if (attempt < maxRetries - 1) {
        await Future.delayed(delays[attempt]);
      }
    }
    return {'success': false, 'error': 'Error desconocido'};
  }

  /// Envia la venta al endpoint PV exclusivamente.
  /// Retorna mapa con success, docto_pv_id, folio o lanza excepcion si falla.
  Future<Map<String, dynamic>?> _uploadSale(VentaPendiente v) async {
    if (v.esNoVenta) {
      return await _uploadNoVentaPv(v);
    }
    return await _uploadSalePv(v);
  }

  Future<Map<String, dynamic>?> _uploadNoVentaPv(VentaPendiente v) async {
    try {
      // Subida multipart: los datos de la no venta + el archivo de la foto.
      // El servidor guarda la imagen en disco (Storage:FotosPath) y deja la
      // referencia en DOCTOS_PV.DESCRIPCION (segmento FOTO:). Si el archivo
      // ya no existe (foto simulada o borrada), se envía sin adjunto y la
      // no venta se registra igual.
      final detalle = v.detalles.isNotEmpty ? v.detalles.first : {};
      final fotoPath = detalle['foto_path'] as String?;
      final tieneFotoValida =
          fotoPath != null &&
          fotoPath.isNotEmpty &&
          File(fotoPath).existsSync() &&
          File(fotoPath).lengthSync() > 100;

      if (fotoPath != null && fotoPath.isNotEmpty && !tieneFotoValida) {
        debugPrint(
          '[NoVenta] Advertencia: Archivo de foto no existe o está vacío en ruta: $fotoPath',
        );
      }

      final formData = FormData.fromMap({
        'payload': jsonEncode(v.toNoVentaJson()),
        if (tieneFotoValida)
          'foto': await MultipartFile.fromFile(
            fotoPath!,
            filename: '${v.ventaMovilId}.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
      });

      final response = await _dioClient.dio.post(
        '/api/v1/pv/noventa',
        data: formData,
      );
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'docto_pv_id': data['docto_pv_id'],
          'folio': data['folio'],
        };
      }
      final msg =
          response.data is Map
              ? (response.data['message'] ?? response.data['error'] ?? '')
              : '';
      return {
        'success': false,
        'error':
            'API ERROR [${response.statusCode}]: ${msg.isNotEmpty ? msg : 'Error ${response.statusCode}'}',
      };
    } on DioException catch (e) {
      String serverMsg = '';
      if (e.response?.data is Map) {
        serverMsg =
            e.response?.data['message'] ?? e.response?.data['error'] ?? '';
      } else if (e.response?.data is String) {
        serverMsg = e.response?.data;
      }
      final code = e.response?.statusCode ?? 0;
      return {
        'success': false,
        'error':
            'API ERROR [$code]: ${serverMsg.isNotEmpty ? serverMsg : e.message}',
      };
    }
  }

  /// Envia la venta al endpoint PV: /api/v1/pv/punventa
  Future<Map<String, dynamic>?> _uploadSalePv(VentaPendiente v) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/v1/pv/ventas',
        data: v.toPvJson(),
      );
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'docto_pv_id': data['docto_pv_id'],
          'folio': data['folio'],
        };
      }
      return {
        'success': false,
        'error':
            'API ERROR [${response.statusCode}]: Respuesta inesperada del servidor',
      };
    } on DioException catch (e) {
      String serverMsg = '';
      if (e.response?.data is Map) {
        serverMsg =
            e.response?.data['message'] ?? e.response?.data['error'] ?? '';
      } else if (e.response?.data is String) {
        serverMsg = e.response?.data;
      }
      final code = e.response?.statusCode ?? 0;
      if (code == 0) {
        return {'success': false, 'error': e.message ?? e.toString()};
      }
      return {
        'success': false,
        'error':
            'API ERROR [$code]: ${serverMsg.isNotEmpty ? serverMsg : e.message}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

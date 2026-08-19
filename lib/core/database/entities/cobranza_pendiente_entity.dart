import 'dart:convert';
import 'package:uuid/uuid.dart';

class CobranzaPendiente {
  final String cobranzaMovilId;
  final int vendedorId;
  final int clienteId;
  final String clienteNombre;
  final String fechaHora;
  final String estado;
  final double totalCobrado;
  final List<Map<String, dynamic>> pagos;
  final List<Map<String, dynamic>> documentos;
  final int? doctoPvId;
  final String? folio;

  CobranzaPendiente({
    String? cobranzaMovilId,
    required this.vendedorId,
    required this.clienteId,
    required this.clienteNombre,
    required this.fechaHora,
    this.estado = 'pendiente',
    this.totalCobrado = 0.0,
    this.pagos = const [],
    this.documentos = const [],
    this.doctoPvId,
    this.folio,
  }) : cobranzaMovilId = cobranzaMovilId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'cobranza_movil_id': cobranzaMovilId,
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
      'fecha_hora': fechaHora,
      'pagos':
          pagos
              .map(
                (p) => {
                  'forma_cobro_id': p['forma_cobro_id'] as int,
                  'importe': (p['importe'] as num).toDouble(),
                },
              )
              .toList(),
      'documentos_cobrar':
          documentos
              .map(
                (d) => {
                  'docto_pv_original_id': d['docto_pv_original_id'] as int,
                  'importe_pagado': (d['importe_pagado'] as num).toDouble(),
                },
              )
              .toList(),
    };
  }

  CobranzaPendiente copyWith({String? estado, int? doctoPvId, String? folio}) {
    return CobranzaPendiente(
      cobranzaMovilId: cobranzaMovilId,
      vendedorId: vendedorId,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      fechaHora: fechaHora,
      estado: estado ?? this.estado,
      totalCobrado: totalCobrado,
      pagos: pagos,
      documentos: documentos,
      doctoPvId: doctoPvId ?? this.doctoPvId,
      folio: folio ?? this.folio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cobranza_movil_id': cobranzaMovilId,
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'fecha_hora': fechaHora,
      'estado': estado,
      'total_cobrado': totalCobrado,
      'pagos_json': pagos.isNotEmpty ? jsonEncode(pagos) : null,
      'documentos_json': documentos.isNotEmpty ? jsonEncode(documentos) : null,
      'docto_pv_id': doctoPvId,
      'folio': folio,
    };
  }

  factory CobranzaPendiente.fromMap(Map<String, dynamic> map) {
    return CobranzaPendiente(
      cobranzaMovilId: map['cobranza_movil_id'] as String,
      vendedorId: map['vendedor_id'] as int,
      clienteId: map['cliente_id'] as int,
      clienteNombre: map['cliente_nombre'] as String,
      fechaHora: map['fecha_hora'] as String,
      estado: map['estado'] as String? ?? 'pendiente',
      totalCobrado: (map['total_cobrado'] as num?)?.toDouble() ?? 0.0,
      pagos: _parseJsonList(map['pagos_json'] as String?),
      documentos: _parseJsonList(map['documentos_json'] as String?),
      doctoPvId: map['docto_pv_id'] as int?,
      folio: map['folio'] as String?,
    );
  }

  static List<Map<String, dynamic>> _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

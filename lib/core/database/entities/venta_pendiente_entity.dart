import 'dart:convert';

class VentaPendiente {
  final String ventaMovilId;
  final int vendedorId;
  final int clienteId;
  final String clienteNombre;
  final String fechaHora;
  final String estado;
  final double total;
  final List<Map<String, dynamic>> detalles;
  final int
  formaCobroId; // FK -> FORMAS_COBRO: 67=Efectivo, 71=Credito, 2845=Tarjeta
  final int? cajaId; // FK -> CAJAS (resuelta en el login nativo)
  final int? cajeroId; // FK -> CAJEROS (resuelta en el login nativo)
  final int? almacenId; // FK -> ALMACENES (resuelta en el login nativo)
  final int? sucursalId; // FK -> SUCURSALES (resuelta en el login nativo)
  final String? usuarioCreador; // Usuario nativo de Microsip (USUARIO_CREADOR)
  final int? doctoPvId; // ID del ticket en Microsip (DOCTOS_PV.DOCTO_PV_ID)
  final String? folio; // Folio del ticket en Microsip (ej: V000000123)
  final String? folioLocal; // Folio provisional offline (ej: PRV-0000001)
  final List<Map<String, dynamic>>?
  pagos; // [{forma_cobro_id, importe}, ...] para pagos mixtos

  VentaPendiente({
    required this.ventaMovilId,
    required this.vendedorId,
    required this.clienteId,
    required this.clienteNombre,
    required this.fechaHora,
    this.estado = 'pendiente',
    this.total = 0.0,
    this.detalles = const [],
    this.formaCobroId = 67, // Default: Efectivo
    this.cajaId,
    this.cajeroId,
    this.almacenId,
    this.sucursalId,
    this.usuarioCreador,
    this.doctoPvId,
    this.folio,
    this.folioLocal,
    this.pagos,
  });

  /// Indica si esta operación es una NO VENTA (no genera ticket).
  ///
  /// Se identifica por su estado `'no_venta'` o porque su primer detalle
  /// trae una `causa_id` (motivo). Estas operaciones se muestran como un
  /// resumen (motivo + foto + comentario), nunca como un ticket de venta.
  bool get esNoVenta {
    if (estado == 'no_venta') return true;
    if (detalles.isNotEmpty && detalles.first.containsKey('causa_id')) {
      return true;
    }
    return false;
  }

  /// Convierte a JSON para enviar al endpoint /api/v1/pv/ventas
  /// La identidad (caja, cajero, almacen, usuario) se resuelve en el login
  /// nativo; el servidor la usa cuando reprocesa la cola offline.
  Map<String, dynamic> toPvJson() {
    final result = <String, dynamic>{
      'venta_movil_id': ventaMovilId,
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
      'fecha_hora': fechaHora,
      'forma_cobro_id': formaCobroId,
      'notas': 'Pedido Movil - ID: $ventaMovilId',
      'detalles':
          detalles
              .map(
                (d) => {
                  'articulo_id': d['articulo_id'] as int,
                  'unidades': (d['unidades'] as num).toDouble(),
                  'precio_unitario': (d['precio_unitario'] as num).toDouble(),
                  'impuesto_id':
                      d['impuesto_id'] as int? ?? 622, // Default: IVA 16%
                  if (d['impuestos'] is List &&
                      (d['impuestos'] as List).isNotEmpty)
                    'impuestos': d['impuestos'] as List,
                },
              )
              .toList(),
    };
    if (cajaId != null) result['caja_id'] = cajaId;
    if (cajeroId != null) result['cajero_id'] = cajeroId;
    if (almacenId != null) result['almacen_id'] = almacenId;
    if (sucursalId != null) result['sucursal_id'] = sucursalId;
    if (usuarioCreador != null && usuarioCreador!.isNotEmpty) {
      result['usuario_creador'] = usuarioCreador;
    }
    if (pagos != null && pagos!.isNotEmpty) {
      result['pagos'] = pagos;
    }
    return result;
  }

  /// Campos de la no venta para subida multipart (foto incluida).
  /// `foto_path` (ruta local del archivo) no viaja como campo: el archivo
  /// se adjunta como `MultipartFile` y el servidor lo guarda en disco
  /// (Storage:FotosPath), dejando la referencia en `DOCTOS_PV.DESCRIPCION`
  /// (segmento FOTO:).
  Map<String, String> toNoVentaFields() {
    final detalle = detalles.isNotEmpty ? detalles.first : {};
    return {
      'venta_movil_id': ventaMovilId,
      'vendedor_id': '$vendedorId',
      'cliente_id': '$clienteId',
      'fecha_hora': fechaHora,
      'causa_id': '${detalle['causa_id'] as int? ?? 0}',
      'causa_desc': detalle['causa_desc'] as String? ?? 'Sin causa',
      'comentario': detalle['comentario'] as String? ?? '',
      if (cajaId != null) 'caja_id': '$cajaId',
      if (cajeroId != null) 'cajero_id': '$cajeroId',
      if (almacenId != null) 'almacen_id': '$almacenId',
      if (sucursalId != null) 'sucursal_id': '$sucursalId',
      if (usuarioCreador != null && usuarioCreador!.isNotEmpty)
        'usuario_creador': usuarioCreador!,
    };
  }

  /// Convierte a JSON para enviar al endpoint /api/v1/pv/noventa
  Map<String, dynamic> toNoVentaJson() {
    final detalle = detalles.isNotEmpty ? detalles.first : {};
    final result = <String, dynamic>{
      'venta_movil_id': ventaMovilId,
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
      'fecha_hora': fechaHora,
      'causa_id': detalle['causa_id'] as int? ?? 0,
      'causa_desc': detalle['causa_desc'] as String? ?? 'Sin causa',
      'comentario': detalle['comentario'] as String?,
      'foto_path': detalle['foto_path'] as String?,
    };
    if (cajaId != null) result['caja_id'] = cajaId;
    if (cajeroId != null) result['cajero_id'] = cajeroId;
    if (almacenId != null) result['almacen_id'] = almacenId;
    if (sucursalId != null) result['sucursal_id'] = sucursalId;
    if (usuarioCreador != null && usuarioCreador!.isNotEmpty) {
      result['usuario_creador'] = usuarioCreador;
    }
    return result;
  }

  /// Convierte a JSON para enviar al endpoint /api/v1/ventas (original)
  Map<String, dynamic> toVentaJson() => {
    'venta_movil_id': ventaMovilId,
    'vendedor_id': vendedorId,
    'cliente_id': clienteId,
    'fecha_hora': fechaHora,
    'notas': 'Pedido Movil - ID: $ventaMovilId',
    'detalles':
        detalles
            .map(
              (d) => {
                'articulo_id': d['articulo_id'] as int,
                'unidades': (d['unidades'] as num).toDouble(),
                'precio_unitario': (d['precio_unitario'] as num).toDouble(),
              },
            )
            .toList(),
  };

  VentaPendiente copyWith({
    String? estado,
    int? doctoPvId,
    String? folio,
    String? folioLocal,
    List<Map<String, dynamic>>? pagos,
  }) => VentaPendiente(
    ventaMovilId: ventaMovilId,
    vendedorId: vendedorId,
    clienteId: clienteId,
    clienteNombre: clienteNombre,
    fechaHora: fechaHora,
    estado: estado ?? this.estado,
    total: total,
    detalles: detalles,
    formaCobroId: formaCobroId,
    cajaId: cajaId,
    cajeroId: cajeroId,
    almacenId: almacenId,
    sucursalId: sucursalId,
    usuarioCreador: usuarioCreador,
    doctoPvId: doctoPvId ?? this.doctoPvId,
    folio: folio ?? this.folio,
    folioLocal: folioLocal ?? this.folioLocal,
    pagos: pagos ?? this.pagos,
  );

  Map<String, dynamic> toMap() => {
    'venta_movil_id': ventaMovilId,
    'vendedor_id': vendedorId,
    'cliente_id': clienteId,
    'cliente_nombre': clienteNombre,
    'fecha_hora': fechaHora,
    'estado': estado,
    'total': total,
    'detalles_json': jsonEncode(detalles),
    'forma_cobro_id': formaCobroId,
    'caja_id': cajaId,
    'cajero_id': cajeroId,
    'almacen_id': almacenId,
    'sucursal_id': sucursalId,
    'usuario_creador': usuarioCreador,
    'docto_pv_id': doctoPvId,
    'folio': folio,
    'folio_local': folioLocal,
    'pagos_json': pagos != null ? jsonEncode(pagos) : null,
  };

  factory VentaPendiente.fromMap(Map<String, dynamic> map) => VentaPendiente(
    ventaMovilId: map['venta_movil_id'] as String,
    vendedorId: map['vendedor_id'] as int,
    clienteId: map['cliente_id'] as int,
    clienteNombre: map['cliente_nombre'] as String,
    fechaHora: map['fecha_hora'] as String,
    estado: map['estado'] as String? ?? 'pendiente',
    total: (map['total'] as num?)?.toDouble() ?? 0.0,
    detalles: _parseDetalles(map['detalles_json'] as String?),
    formaCobroId: map['forma_cobro_id'] as int? ?? 67,
    cajaId: map['caja_id'] as int?,
    cajeroId: map['cajero_id'] as int?,
    almacenId: map['almacen_id'] as int?,
    sucursalId: map['sucursal_id'] as int?,
    usuarioCreador: map['usuario_creador'] as String?,
    doctoPvId: map['docto_pv_id'] as int?,
    folio: map['folio'] as String?,
    folioLocal: map['folio_local'] as String?,
    pagos: _parseDetalles(map['pagos_json'] as String?),
  );

  static List<Map<String, dynamic>> _parseDetalles(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

/// Agrupa las cantidades vendidas por artículo a partir de los detalles de
/// una venta. Se usa para descontar/reponer existencias del almacén.
/// Ignora artículos sin `articulo_id` o con `unidades <= 0`.
Map<int, int> cantidadesPorArticulo(List<Map<String, dynamic>> detalles) {
  final cantidades = <int, int>{};
  for (final d in detalles) {
    final articuloId = d['articulo_id'] as int?;
    final unidades = (d['unidades'] as num?)?.toInt() ?? 0;
    if (articuloId == null || unidades <= 0) continue;
    cantidades[articuloId] = (cantidades[articuloId] ?? 0) + unidades;
  }
  return cantidades;
}

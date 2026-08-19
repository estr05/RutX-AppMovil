import 'dart:convert';

class ImpuestoProducto {
  final int impuestoId;
  final double pctjeImpuesto;

  ImpuestoProducto({required this.impuestoId, required this.pctjeImpuesto});

  Map<String, dynamic> toMap() => {
    'impuesto_id': impuestoId,
    'pctje_impuesto': pctjeImpuesto,
  };

  factory ImpuestoProducto.fromMap(Map<String, dynamic> map) =>
      ImpuestoProducto(
        impuestoId: map['impuesto_id'] as int,
        pctjeImpuesto: (map['pctje_impuesto'] as num?)?.toDouble() ?? 0.0,
      );
}

class Producto {
  final int articuloId;
  final String nombre;
  final String estatus;
  final String clave;
  final double precio; // Sin impuestos (PRECIOS_ARTICULOS, lista 42)
  final double precioConImpuesto; // Con impuestos compuestos (∏ 1+pctje/100)
  final int porcentajeImpuesto; // Impuesto principal (0, 16, etc.)
  final int impuestoId; // Impuesto principal (622, 2204, etc.)
  final List<ImpuestoProducto> impuestos; // Impuestos reales del articulo

  // Nuevos campos para detalle
  final double existenciasGral;
  final double existencias;
  final double peso;
  final double merma;
  final String permiteMerma;

  Producto({
    required this.articuloId,
    required this.nombre,
    this.estatus = 'A',
    required this.clave,
    required this.precio,
    this.precioConImpuesto = 0.0,
    this.porcentajeImpuesto = 16,
    this.impuestoId = 622,
    this.impuestos = const [],
    this.existenciasGral = 0.0,
    this.existencias = 0.0,
    this.peso = 0.0,
    this.merma = 0.0,
    this.permiteMerma = 'No',
  });

  Map<String, dynamic> toMap() => {
    'articulo_id': articuloId,
    'nombre': nombre,
    'estatus': estatus,
    'clave': clave,
    'precio': precio,
    'precio_con_impuesto': precioConImpuesto,
    'porcentaje_impuesto': porcentajeImpuesto,
    'impuesto_id': impuestoId,
    'impuestos_json':
        impuestos.isEmpty
            ? null
            : jsonEncode(impuestos.map((i) => i.toMap()).toList()),
    'existencias_gral': existenciasGral,
    'existencias': existencias,
    'peso': peso,
    'merma': merma,
    'permite_merma': permiteMerma,
  };

  factory Producto.fromMap(Map<String, dynamic> map) {
    final id = map['articulo_id'] as int;
    final clave = map['clave'] as String?;
    final precio = (map['precio'] as num?)?.toDouble();
    if (clave == null || precio == null) {
      throw StateError(
        'Producto #$id: datos inválidos desde la BD. '
        '${clave == null ? "clave" : "precio"} es null. '
        'Revise la sincronización o los datos en Firebird.',
      );
    }
    return Producto(
      articuloId: id,
      nombre: map['nombre'] as String,
      estatus: map['estatus'] as String? ?? 'A',
      clave: clave,
      precio: precio,
      precioConImpuesto:
          (map['precio_con_impuesto'] as num?)?.toDouble() ?? 0.0,
      porcentajeImpuesto: map['porcentaje_impuesto'] as int? ?? 16,
      impuestoId: map['impuesto_id'] as int? ?? 622,
      impuestos: _parseImpuestos(map['impuestos_json'] as String?),
      existenciasGral: (map['existencias_gral'] as num?)?.toDouble() ?? 0.0,
      existencias: (map['existencias'] as num?)?.toDouble() ?? 0.0,
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      merma: (map['merma'] as num?)?.toDouble() ?? 0.0,
      permiteMerma: map['permite_merma'] as String? ?? 'No',
    );
  }

  static List<ImpuestoProducto> _parseImpuestos(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ImpuestoProducto.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

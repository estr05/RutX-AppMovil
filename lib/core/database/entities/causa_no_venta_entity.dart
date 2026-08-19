class CausaNoVenta {
  static const List<CausaNoVenta> causasSemilla = [
    CausaNoVenta(causaId: 1, descripcion: 'CERRADO'),
    CausaNoVenta(causaId: 2, descripcion: 'SIN DINERO'),
    CausaNoVenta(causaId: 3, descripcion: 'NO ESTÁ EL DUEÑO'),
    CausaNoVenta(causaId: 4, descripcion: 'NO NECESITA'),
    CausaNoVenta(causaId: 5, descripcion: 'OTRO'),
  ];

  final int causaId;
  final String descripcion;
  final String estatus;

  const CausaNoVenta({
    required this.causaId,
    required this.descripcion,
    this.estatus = 'A',
  });

  Map<String, dynamic> toMap() {
    return {
      'causa_id': causaId,
      'descripcion': descripcion,
      'estatus': estatus,
    };
  }

  factory CausaNoVenta.fromMap(Map<String, dynamic> map) {
    return CausaNoVenta(
      causaId: map['causa_id'] as int,
      descripcion: map['descripcion'] as String,
      estatus: map['estatus'] as String? ?? 'A',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CausaNoVenta &&
        other.causaId == causaId &&
        other.descripcion == descripcion;
  }

  @override
  int get hashCode => causaId.hashCode ^ descripcion.hashCode;
}

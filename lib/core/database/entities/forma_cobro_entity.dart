/// Representa una Forma de Cobro sincronizada dinámicamente desde Microsip.
///
/// Permite clasificar si una forma de cobro es de Contado (tipo 'C')
/// o Crédito (tipo 'R') sin harcodear IDs numéricos en el código de la app.
class FormaCobro {
  final int formaCobroId;
  final String nombre;
  final String tipo; // 'C' = Contado / Efectivo, 'R' = Crédito / CxC
  final String estatus;

  const FormaCobro({
    required this.formaCobroId,
    required this.nombre,
    required this.tipo,
    this.estatus = 'A',
  });

  /// Determina semánticamente si la forma de cobro es de tipo Contado/Efectivo
  bool get esContado => tipo.toUpperCase() == 'C';

  /// Determina semánticamente si la forma de cobro es de tipo Crédito
  bool get esCredito => tipo.toUpperCase() == 'R';

  Map<String, dynamic> toMap() {
    return {
      'forma_cobro_id': formaCobroId,
      'nombre': nombre,
      'tipo': tipo,
      'estatus': estatus,
    };
  }

  factory FormaCobro.fromMap(Map<String, dynamic> map) {
    return FormaCobro(
      formaCobroId: map['forma_cobro_id'] as int,
      nombre: map['nombre'] as String? ?? 'EFECTIVO',
      tipo: map['tipo'] as String? ?? 'C',
      estatus: map['estatus'] as String? ?? 'A',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormaCobro && other.formaCobroId == formaCobroId;
  }

  @override
  int get hashCode => formaCobroId.hashCode;
}

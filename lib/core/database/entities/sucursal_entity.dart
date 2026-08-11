class Sucursal {
  final int sucursalId;
  final String nombre;
  final String calle;
  final String numExterior;
  final String numInterior;
  final String colonia;
  final String poblacion;
  final String codigoPostal;
  final String telefono;

  Sucursal({
    required this.sucursalId,
    required this.nombre,
    this.calle = '',
    this.numExterior = '',
    this.numInterior = '',
    this.colonia = '',
    this.poblacion = '',
    this.codigoPostal = '',
    this.telefono = '',
  });

  Map<String, dynamic> toMap() => {
        'sucursal_id': sucursalId,
        'nombre': nombre,
        'calle': calle,
        'num_exterior': numExterior,
        'num_interior': numInterior,
        'colonia': colonia,
        'poblacion': poblacion,
        'codigo_postal': codigoPostal,
        'telefono': telefono,
      };

  factory Sucursal.fromMap(Map<String, dynamic> map) => Sucursal(
        sucursalId: map['sucursal_id'] as int,
        nombre: map['nombre'] as String? ?? '',
        calle: map['calle'] as String? ?? '',
        numExterior: map['num_exterior'] as String? ?? '',
        numInterior: map['num_interior'] as String? ?? '',
        colonia: map['colonia'] as String? ?? '',
        poblacion: map['poblacion'] as String? ?? '',
        codigoPostal: map['codigo_postal'] as String? ?? '',
        telefono: map['telefono'] as String? ?? '',
      );

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        sucursalId: json['sucursal_id'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        calle: json['calle'] as String? ?? '',
        numExterior: json['num_exterior'] as String? ?? '',
        numInterior: json['num_interior'] as String? ?? '',
        colonia: json['colonia'] as String? ?? '',
        poblacion: json['poblacion'] as String? ?? '',
        codigoPostal: json['codigo_postal'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
      );
}

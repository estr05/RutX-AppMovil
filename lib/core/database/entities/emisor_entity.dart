class Emisor {
  final String rfc;
  final String nombreFiscal;
  final String domicilioFiscal;
  final String regimenFiscal;

  Emisor({
    required this.rfc,
    required this.nombreFiscal,
    this.domicilioFiscal = '',
    this.regimenFiscal = '',
  });

  Map<String, dynamic> toMap() => {
    'rfc': rfc,
    'nombre_fiscal': nombreFiscal,
    'domicilio_fiscal': domicilioFiscal,
    'regimen_fiscal': regimenFiscal,
  };

  factory Emisor.fromMap(Map<String, dynamic> map) => Emisor(
    rfc: map['rfc'] as String? ?? '',
    nombreFiscal: map['nombre_fiscal'] as String? ?? '',
    domicilioFiscal: map['domicilio_fiscal'] as String? ?? '',
    regimenFiscal: map['regimen_fiscal'] as String? ?? '',
  );

  factory Emisor.fromJson(Map<String, dynamic> json) => Emisor(
    rfc: json['rfc'] as String? ?? '',
    nombreFiscal: json['nombre_fiscal'] as String? ?? '',
    domicilioFiscal: json['domicilio_fiscal'] as String? ?? '',
    regimenFiscal: json['regimen_fiscal'] as String? ?? '',
  );
}

class Cliente {
  final int clienteId;
  final String clave;
  final String nombreCliente;
  final String telefono;
  final String? calle;
  final String? colonia;
  final String poblacion;
  final String? codigoPostal;
  final double limiteCredito;
  final double saldo;
  final int tipoVenta; // 1 = Contado, >1 = Crédito (mapeado de CondPagoId)
  final String? rfc; // RFC del cliente (opcional, desde RFCS_LCO)

  /// Regla identica a la del servidor: limite <= 0 = sin restriccion;
  /// si no, puede recibir credito solo si su saldo es menor al limite.
  bool get puedeCredito => limiteCredito <= 0 || saldo < limiteCredito;

  Cliente({
    required this.clienteId,
    required this.clave,
    required this.nombreCliente,
    required this.telefono,
    this.calle,
    this.colonia,
    required this.poblacion,
    this.codigoPostal,
    this.limiteCredito = 0.0,
    this.saldo = 0.0,
    required this.tipoVenta,
    this.rfc,
  });

  Map<String, dynamic> toMap() => {
        'cliente_id': clienteId,
        'clave': clave,
        'nombre_cliente': nombreCliente,
        'telefono': telefono,
        'calle': calle,
        'colonia': colonia,
        'poblacion': poblacion,
        'codigo_postal': codigoPostal,
        'limite_credito': limiteCredito,
        'saldo': saldo,
        'tipo_venta': tipoVenta,
        'cliente_rfc': rfc,
      };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        clienteId: map['cliente_id'] as int,
        clave: map['clave'] as String? ?? '',
        nombreCliente: map['nombre_cliente'] as String,
        telefono: map['telefono'] as String? ?? '',
        calle: map['calle'] as String?,
        colonia: map['colonia'] as String?,
        poblacion: map['poblacion'] as String? ?? '',
        codigoPostal: map['codigo_postal'] as String?,
        limiteCredito: (map['limite_credito'] as num?)?.toDouble() ?? 0.0,
        saldo: (map['saldo'] as num?)?.toDouble() ?? 0.0,
        tipoVenta: map['tipo_venta'] as int? ?? 1,
        rfc: map['cliente_rfc'] as String?,
      );
}

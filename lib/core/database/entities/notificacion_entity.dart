class Notificacion {
  final int? id;
  final String mensaje;
  final bool leida;
  final String fechaCreacion;

  Notificacion({
    this.id,
    required this.mensaje,
    this.leida = false,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'mensaje': mensaje,
    'leida': leida ? 1 : 0,
    'fecha_creacion': fechaCreacion,
  };

  factory Notificacion.fromMap(Map<String, dynamic> map) => Notificacion(
    id: map['id'] as int?,
    mensaje: map['mensaje'] as String,
    leida: (map['leida'] as int?) == 1,
    fechaCreacion: map['fecha_creacion'] as String,
  );
}

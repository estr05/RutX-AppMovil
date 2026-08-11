class ColaSincronizacion {
  final int? id;
  final String tipo;
  final String entidadId;
  final String estado;
  final int prioridad;
  final String creadoEn;
  final String? sincronizadoEn;
  final int reintentos;
  final String? ultimoError;

  ColaSincronizacion({
    this.id,
    required this.tipo,
    required this.entidadId,
    this.estado = 'pendiente',
    this.prioridad = 0,
    required this.creadoEn,
    this.sincronizadoEn,
    this.reintentos = 0,
    this.ultimoError,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo': tipo,
      'entidad_id': entidadId,
      'estado': estado,
      'prioridad': prioridad,
      'creado_en': creadoEn,
      'sincronizado_en': sincronizadoEn,
      'reintentos': reintentos,
      'ultimo_error': ultimoError,
    };
  }

  factory ColaSincronizacion.fromMap(Map<String, dynamic> map) {
    return ColaSincronizacion(
      id: map['id'] as int?,
      tipo: map['tipo'] as String,
      entidadId: map['entidad_id'] as String,
      estado: map['estado'] as String? ?? 'pendiente',
      prioridad: map['prioridad'] as int? ?? 0,
      creadoEn: map['creado_en'] as String,
      sincronizadoEn: map['sincronizado_en'] as String?,
      reintentos: map['reintentos'] as int? ?? 0,
      ultimoError: map['ultimo_error'] as String?,
    );
  }

  ColaSincronizacion copyWith({
    int? id,
    String? tipo,
    String? entidadId,
    String? estado,
    int? prioridad,
    String? creadoEn,
    String? sincronizadoEn,
    int? reintentos,
    String? ultimoError,
  }) {
    return ColaSincronizacion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      entidadId: entidadId ?? this.entidadId,
      estado: estado ?? this.estado,
      prioridad: prioridad ?? this.prioridad,
      creadoEn: creadoEn ?? this.creadoEn,
      sincronizadoEn: sincronizadoEn ?? this.sincronizadoEn,
      reintentos: reintentos ?? this.reintentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

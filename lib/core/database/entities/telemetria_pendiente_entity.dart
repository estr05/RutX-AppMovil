class TelemetriaPendiente {
  final String clientEventId;
  final String eventType;
  final int? customerId;
  final String? relatedEntityId;
  final int sellerId;
  final String contractNumber;
  final String deviceInstallationId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String occurredAt;
  final String? metadataJson;
  final String estado;
  final int reintentos;
  final String? ultimoError;
  final String creadoEn;
  final String? enviadoEn;

  TelemetriaPendiente({
    required this.clientEventId,
    required this.eventType,
    this.customerId,
    this.relatedEntityId,
    required this.sellerId,
    required this.contractNumber,
    required this.deviceInstallationId,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.occurredAt,
    this.metadataJson,
    this.estado = 'pendiente',
    this.reintentos = 0,
    this.ultimoError,
    required this.creadoEn,
    this.enviadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'client_event_id': clientEventId,
      'event_type': eventType,
      'customer_id': customerId,
      'related_entity_id': relatedEntityId,
      'seller_id': sellerId,
      'contract_number': contractNumber,
      'device_installation_id': deviceInstallationId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'occurred_at': occurredAt,
      'metadata_json': metadataJson,
      'estado': estado,
      'reintentos': reintentos,
      'ultimo_error': ultimoError,
      'creado_en': creadoEn,
      'enviado_en': enviadoEn,
    };
  }

  factory TelemetriaPendiente.fromMap(Map<String, dynamic> map) {
    return TelemetriaPendiente(
      clientEventId: map['client_event_id'] as String,
      eventType: map['event_type'] as String,
      customerId: map['customer_id'] as int?,
      relatedEntityId: map['related_entity_id'] as String?,
      sellerId: map['seller_id'] as int,
      contractNumber: map['contract_number'] as String,
      deviceInstallationId: map['device_installation_id'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      accuracy: map['accuracy'] as double?,
      occurredAt: map['occurred_at'] as String,
      metadataJson: map['metadata_json'] as String?,
      estado: map['estado'] as String,
      reintentos: map['reintentos'] as int,
      ultimoError: map['ultimo_error'] as String?,
      creadoEn: map['creado_en'] as String,
      enviadoEn: map['enviado_en'] as String?,
    );
  }
}

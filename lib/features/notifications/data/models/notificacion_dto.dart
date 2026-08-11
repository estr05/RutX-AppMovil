class NotificacionDto {
  final int vendedorId;
  final String contenido;
  final String fechaEnvio;

  NotificacionDto({
    required this.vendedorId,
    required this.contenido,
    required this.fechaEnvio,
  });

  factory NotificacionDto.fromJson(Map<String, dynamic> json) => NotificacionDto(
        vendedorId: json['vendedorId'] as int,
        contenido: json['contenido'] as String,
        fechaEnvio: json['fechaEnvio'] as String,
      );
}

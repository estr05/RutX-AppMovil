/// Folio provisional local (offline) de una caja/cajero.
///
/// Cuando el dispositivo no tiene señal, cada venta obtiene un folio
/// provisional consecutivo de esta tabla (ej: PRV-0000001). Al sincronizar,
/// el servidor asigna el folio real de Microsip que lo reemplaza en pantalla.
class FolioLocal {
  final int cajeroId;
  final int consecutivo;
  final String? actualizadoEn;

  const FolioLocal({
    required this.cajeroId,
    required this.consecutivo,
    this.actualizadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'cajero_id': cajeroId,
      'consecutivo': consecutivo,
      'actualizado_en': actualizadoEn ?? DateTime.now().toIso8601String(),
    };
  }

  factory FolioLocal.fromMap(Map<String, dynamic> map) {
    return FolioLocal(
      cajeroId: map['cajero_id'] as int,
      consecutivo: map['consecutivo'] as int? ?? 0,
      actualizadoEn: map['actualizado_en'] as String?,
    );
  }

  FolioLocal copyWith({int? consecutivo, String? actualizadoEn}) {
    return FolioLocal(
      cajeroId: cajeroId,
      consecutivo: consecutivo ?? this.consecutivo,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}

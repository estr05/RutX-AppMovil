class ErrorUtils {
  static String getFriendlyErrorMessage(String technicalError) {
    if (technicalError.contains("API ERROR [401]")) {
      return "Tu sesión ha caducado. Inicia sesión de nuevo.";
    } else if (technicalError.contains("NETWORK ERROR") ||
        technicalError.contains("Sin conexión") ||
        technicalError.contains("network is unreachable")) {
      return "Guardado localmente. Se enviará automáticamente cuando recuperes la conexión.";
    } else if (technicalError.contains("API ERROR")) {
      final backendDetail = technicalError.replaceFirst("API ERROR", "").trim();
      return "Error del servidor: ${backendDetail.isNotEmpty ? backendDetail : "revise el backend"}";
    } else if (technicalError.contains("APP ERROR")) {
      return "Algo salió mal en la aplicación. Intenta cerrarla y volverla a abrir.";
    }
    return "No se pudo sincronizar. Se seguirá intentando en segundo plano.";
  }
}

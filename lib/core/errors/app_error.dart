class AppError {
  final String mensajeUsuario;
  final String? detalleTecnico;
  final bool esRecuperable;

  AppError({
    required this.mensajeUsuario,
    this.detalleTecnico,
    this.esRecuperable = true,
  });
}

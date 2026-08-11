sealed class SyncResult {}

class SyncSuccess extends SyncResult {
  final int clientes;
  final int productos;
  final int credito;
  SyncSuccess({required this.clientes, required this.productos, this.credito = 0});
}

class SyncFailure extends SyncResult {
  final String mensaje;
  final int intentos;
  SyncFailure({required this.mensaje, this.intentos = 3});
}

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _vendedorIdKey = 'vendedor_id';
  static const String _vendedorNombreKey = 'vendedor_nombre';
  static const String _usuarioKey = 'usuario';
  static const String _cajeroIdKey = 'cajero_id';
  static const String _cajaIdKey = 'caja_id';
  static const String _almacenIdKey = 'almacen_id';
  static const String _sucursalIdKey = 'sucursal_id';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> saveVendedorId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vendedorIdKey, id);
  }

  Future<int?> getVendedorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_vendedorIdKey);
  }

  Future<void> saveVendedorNombre(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vendedorNombreKey, nombre);
  }

  Future<String?> getVendedorNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vendedorNombreKey);
  }

  Future<void> saveUsuario(String usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usuarioKey, usuario);
  }

  Future<String?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usuarioKey);
  }

  Future<void> saveCajeroId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cajeroIdKey, id);
  }

  Future<int?> getCajeroId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cajeroIdKey);
  }

  Future<void> saveCajaId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cajaIdKey, id);
  }

  Future<int?> getCajaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cajaIdKey);
  }

  Future<void> saveAlmacenId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_almacenIdKey, id);
  }

  Future<int?> getAlmacenId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_almacenIdKey);
  }

  Future<void> saveSucursalId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sucursalIdKey, id);
  }

  Future<int?> getSucursalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sucursalIdKey);
  }

  /// Guarda toda la identidad de ruta resuelta en el login nativo.
  Future<void> saveIdentidad({
    required int vendedorId,
    required String vendedorNombre,
    required String usuario,
    required int cajeroId,
    required int cajaId,
    required int almacenId,
    required int sucursalId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vendedorIdKey, vendedorId);
    await prefs.setString(_vendedorNombreKey, vendedorNombre);
    await prefs.setString(_usuarioKey, usuario);
    await prefs.setInt(_cajeroIdKey, cajeroId);
    await prefs.setInt(_cajaIdKey, cajaId);
    await prefs.setInt(_almacenIdKey, almacenId);
    await prefs.setInt(_sucursalIdKey, sucursalId);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_vendedorIdKey);
    await prefs.remove(_vendedorNombreKey);
    await prefs.remove(_usuarioKey);
    await prefs.remove(_cajeroIdKey);
    await prefs.remove(_cajaIdKey);
    await prefs.remove(_almacenIdKey);
    await prefs.remove(_sucursalIdKey);
    await prefs.remove('has_sync_data');
  }

  Future<void> setSyncData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_sync_data', value);
  }

  Future<bool> hasSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_sync_data') ?? false;
  }

  Future<void> setDiaCerrado(String fecha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dia_cerrado', fecha);
  }

  Future<String?> getDiaCerrado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dia_cerrado');
  }

  Future<void> clearDiaCerrado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dia_cerrado');
  }
}

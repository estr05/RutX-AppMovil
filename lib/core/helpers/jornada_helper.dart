import 'package:shared_preferences/shared_preferences.dart';

class JornadaHelper {
  static const String _diaCerradoKey = 'dia_cerrado';

  /// Verifica si la jornada actual ya fue cerrada
  static Future<bool> jornadaCerradaHoy() async {
    final prefs = await SharedPreferences.getInstance();
    final diaCerrado = prefs.getString(_diaCerradoKey);

    if (diaCerrado == null || diaCerrado.isEmpty) return false;

    return _esMismoDia(diaCerrado);
  }

  /// Guarda la fecha de cierre de jornada
  static Future<void> guardarCierreJornada(DateTime fecha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diaCerradoKey, fecha.toIso8601String());
  }

  /// Limpia el estado de cierre de jornada
  static Future<void> limpiarCierreJornada() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_diaCerradoKey);
  }

  /// Compara si una cadena ISO 8601 es del mismo día que hoy
  static bool _esMismoDia(String isoDateString) {
    try {
      final fechaGuardada = DateTime.parse(isoDateString);
      final ahora = DateTime.now();
      return fechaGuardada.year == ahora.year &&
          fechaGuardada.month == ahora.month &&
          fechaGuardada.day == ahora.day;
    } catch (_) {
      return false;
    }
  }
}

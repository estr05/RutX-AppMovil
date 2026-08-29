import 'package:geolocator/geolocator.dart';

class LocationProvider {
  static final LocationProvider _instance = LocationProvider._();
  factory LocationProvider() => _instance;
  LocationProvider._();

  /// Intenta obtener la ubicación actual (best-effort).
  /// Retorna null si no hay permisos, si está desactivado o si toma más de 5 segundos.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Si falla por timeout u otra razón, retornamos null silenciosamente
      return null;
    }
  }
}

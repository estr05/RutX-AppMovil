import 'package:uuid/uuid.dart';
import '../storage/local_storage.dart';

class DeviceIdentityProvider {
  static final DeviceIdentityProvider _instance = DeviceIdentityProvider._();
  factory DeviceIdentityProvider() => _instance;
  DeviceIdentityProvider._();

  final LocalStorage _storage = LocalStorage();

  Future<String> getOrCreateDeviceInstallationId() async {
    String? existingId = await _storage.getDeviceInstallationId();
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    String newId = const Uuid().v4();
    await _storage.saveDeviceInstallationId(newId);
    return newId;
  }
}

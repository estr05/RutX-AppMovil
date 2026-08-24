import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/constants/api_constants.dart';

void main() {
  group('ApiConstants.resolveBaseUrl', () {
    test('Vacio conserva el comportamiento historico LAN/Tailscale', () {
      final url = ApiConstants.resolveBaseUrl('');

      expect(url, startsWith('http://'));
      expect(url, endsWith(':5047'));
      expect(url, ApiConstants.tailscaleCasaUrl);
    });

    test('Solo espacios equivale a ausencia del define', () {
      expect(ApiConstants.resolveBaseUrl('   '), ApiConstants.tailscaleCasaUrl);
    });

    test('URL https valida se respeta tal cual', () {
      expect(
        ApiConstants.resolveBaseUrl('https://sync.demo.com'),
        'https://sync.demo.com',
      );
    });

    test('Recorta el slash final de la URL publica', () {
      expect(
        ApiConstants.resolveBaseUrl('https://sync.demo.com/'),
        'https://sync.demo.com',
      );
    });

    test('Acepta esquema en mayusculas', () {
      expect(
        ApiConstants.resolveBaseUrl('HTTPS://Sync.Demo.Com'),
        'HTTPS://Sync.Demo.Com',
      );
    });

    test('Rechaza http explicito en build de produccion', () {
      expect(
        () => ApiConstants.resolveBaseUrl('http://sync.demo.com'),
        throwsArgumentError,
      );
    });

    test('Rechaza valor sin esquema', () {
      expect(
        () => ApiConstants.resolveBaseUrl('sync.demo.com'),
        throwsArgumentError,
      );
    });
  });
}

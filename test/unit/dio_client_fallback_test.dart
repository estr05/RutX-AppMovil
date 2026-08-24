import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/constants/api_constants.dart';
import 'package:rutx_movil/core/network/dio_client.dart';

void main() {
  group('DioClient.fallbackCandidates', () {
    test('En produccion no hay fallback a IPs privadas', () {
      expect(DioClient.fallbackCandidates(esProduccion: true), isEmpty);
    });

    test('Una URL https fallida tampoco habilita fallback', () {
      expect(
        DioClient.fallbackCandidates(
          esProduccion: true,
          urlFallada: 'https://sync.demo.com',
        ),
        isEmpty,
      );
      expect(
        DioClient.fallbackCandidates(urlFallada: 'https://sync.demo.com'),
        isEmpty,
      );
    });

    test('En desarrollo ofrece las dos URLs conocidas por HTTP', () {
      final candidatos = DioClient.fallbackCandidates();

      expect(candidatos, hasLength(2));
      for (final candidato in candidatos) {
        expect(candidato, startsWith('http://'));
        expect(candidato, endsWith(':5047'));
      }
      expect(candidatos, contains(ApiConstants.empresaUrl));
      expect(candidatos, contains(ApiConstants.tailscaleCasaUrl));
    });

    test('Excluye la URL que acaba de fallar', () {
      final candidatos = DioClient.fallbackCandidates(
        urlFallada: ApiConstants.empresaUrl,
      );

      expect(candidatos, isNot(contains(ApiConstants.empresaUrl)));
      expect(candidatos, contains(ApiConstants.tailscaleCasaUrl));
    });
  });
}

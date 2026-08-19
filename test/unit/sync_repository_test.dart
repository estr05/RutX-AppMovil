import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutx_movil/core/network/sync_result.dart';
import 'package:rutx_movil/features/sync/data/sync_repository.dart';

Dio _createMockDio({int? statusCode, DioExceptionType? errorType}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (errorType != null) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: errorType,
              response:
                  statusCode != null
                      ? Response(
                        requestOptions: options,
                        statusCode: statusCode,
                      )
                      : null,
            ),
          );
        } else if (statusCode != null && statusCode != 200) {
          handler.resolve(
            Response(requestOptions: options, statusCode: statusCode, data: {}),
          );
        }
      },
    ),
  );
  return dio;
}

void main() {
  late SyncRepository repo;

  group('downloadMorningData', () {
    test('NO reintenta en 401, retorna SyncFailure inmediato', () async {
      final dio = _createMockDio(
        errorType: DioExceptionType.badResponse,
        statusCode: 401,
      );
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect(result, isA<SyncFailure>());
      expect((result as SyncFailure).intentos, 1);
    });

    test('reintenta en 500 hasta 3 veces y retorna SyncFailure', () async {
      final dio = _createMockDio(
        errorType: DioExceptionType.badResponse,
        statusCode: 500,
      );
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect(result, isA<SyncFailure>());
      expect((result as SyncFailure).intentos, 3);
    });

    test('retorna SyncFailure cuando status code no es 200', () async {
      final dio = _createMockDio(statusCode: 404);
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect(result, isA<SyncFailure>());
    });

    test('connectionTimeout reintenta 3 veces', () async {
      final dio = _createMockDio(errorType: DioExceptionType.connectionTimeout);
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect((result as SyncFailure).intentos, 3);
    });

    test('receiveTimeout reintenta 3 veces', () async {
      final dio = _createMockDio(errorType: DioExceptionType.receiveTimeout);
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect((result as SyncFailure).intentos, 3);
    });

    test('connectionError reintenta 3 veces', () async {
      final dio = _createMockDio(errorType: DioExceptionType.connectionError);
      repo = SyncRepository(dio: dio);

      final result = await repo.downloadMorningData(7);

      expect((result as SyncFailure).intentos, 3);
    });
  });
}

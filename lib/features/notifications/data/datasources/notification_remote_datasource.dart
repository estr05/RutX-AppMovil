import '../../../../core/network/dio_client.dart';
import '../../../../core/network/connection_state_service.dart';
import '../models/notificacion_dto.dart';

class NotificationRemoteDataSource {
  final DioClient _dioClient = DioClient();

  Future<List<NotificacionDto>> fetchNotificaciones(int vendedorId) async {
    if (ConnectionStateService().currentState == RutxConnectionState.offline) {
      return [];
    }
    final response = await _dioClient.dio.get(
      '/api/v1/messages',
      queryParameters: {'vendedorId': vendedorId},
    );

    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => NotificacionDto.fromJson(json as Map<String, dynamic>)).toList();
  }
}

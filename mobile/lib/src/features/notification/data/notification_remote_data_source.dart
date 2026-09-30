import '../../../core/network/dio_client.dart';
import 'dtos/notification_dtos.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<NotificationDto>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final response = await _client.get(
      '/notifications',
      queryParameters: {if (unreadOnly) 'unreadOnly': true},
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(NotificationDto.fromJson)
        .toList(growable: false);
  }

  /// 204 sin cuerpo en ambos casos de marcado.
  Future<void> markAsRead(String id) =>
      _client.patch('/notifications/$id/read');

  Future<void> markAllAsRead() => _client.patch('/notifications/read-all');
}

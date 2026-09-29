import '../../../core/network/dio_client.dart';
import 'dtos/sesion_dto.dart';

class SeguridadRemoteDataSource {
  const SeguridadRemoteDataSource(this._client);

  final ApiClient _client;

  /// Cabecera con la que el backend identifica la sesión en curso para marcar
  /// `es_actual` (04 §4.9, `UsersController.GetSessions`).
  static const currentSessionHeader = 'X-Refresh-Token';

  Future<List<SesionDto>> fetchSessions({String? refreshToken}) async {
    final response = await _client.get(
      '/users/sessions',
      headers: refreshToken == null || refreshToken.isEmpty
          ? null
          : {currentSessionHeader: refreshToken},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SesionDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String id) async {
    await _client.delete('/users/sessions/$id');
  }

  Future<void> changePassword({
    required String actual,
    required String nueva,
  }) async {
    await _client.put(
      '/users/change-password',
      data: ChangePasswordRequestDto(
        currentPassword: actual,
        newPassword: nueva,
      ).toJson(),
    );
  }
}

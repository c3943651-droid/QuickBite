import '../../../core/network/dio_client.dart';
import 'dtos/auth_dtos.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: LoginRequestDto(email: email, password: password).toJson(),
    );
    return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    await _client.post(
      '/auth/register',
      data: RegisterRequestDto(
        nombre: nombre,
        email: email,
        password: password,
        telefono: telefono,
        rol: rol,
      ).toJson(),
    );
  }

  Future<RefreshResponseDto> refresh({required String refreshToken}) async {
    final response = await _client.post(
      '/auth/refresh',
      data: RefreshRequestDto(refreshToken: refreshToken).toJson(),
    );
    return RefreshResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      '/auth/logout',
      data: LogoutRequestDto(refreshToken: refreshToken).toJson(),
    );
  }
}

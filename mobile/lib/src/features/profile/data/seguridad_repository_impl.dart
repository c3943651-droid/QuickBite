import '../../../core/session/token_storage.dart';
import '../domain/seguridad_repository.dart';
import '../domain/sesion_usuario.dart';
import 'dtos/sesion_dto.dart';
import 'seguridad_remote_data_source.dart';

class SeguridadRepositoryImpl implements SeguridadRepository {
  const SeguridadRepositoryImpl(this._remote, this._tokenStorage);

  final SeguridadRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  /// Identifica la sesión en curso: sin el token de refresco la API no puede
  /// resolver `es_actual` y todas las sesiones saldrían revocables (04 §4.9).
  @override
  Future<List<SesionUsuario>> fetchSessions() async {
    final stored = await _tokenStorage.read();
    final refreshToken = stored?.refreshToken;
    final dtos = await _remote.fetchSessions(refreshToken: refreshToken);
    return dtos.map(_aEntidad).toList();
  }

  @override
  Future<void> revokeSession(String id) => _remote.revokeSession(id);

  @override
  Future<void> changePassword({required String actual, required String nueva}) {
    return _remote.changePassword(actual: actual, nueva: nueva);
  }

  SesionUsuario _aEntidad(SesionDto dto) {
    return SesionUsuario(
      id: dto.id,
      ipOrigen: dto.ipOrigen,
      userAgent: dto.userAgent,
      creadoEn: dto.creadoEn,
      expiraEn: dto.expiraEn,
      esActual: dto.esActual,
    );
  }
}

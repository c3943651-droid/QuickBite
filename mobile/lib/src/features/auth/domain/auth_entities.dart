import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;

  bool get isCliente => rol == 'cliente';
  bool get isRepartidor => rol == 'repartidor';
  bool get isAdmin => rol == 'administrador';

  /// Ruta a la que este rol entra tras autenticarse (07.1 SCR-AUTH-02, 07 §10.3).
  ///
  /// Vive en el dominio y no en el router para que la regla tenga una sola
  /// fuente: el login, el splash y el guard del shell consultan lo mismo. El
  /// administrador no tiene superficie propia en la app móvil, así que entra
  /// por el catálogo.
  String get homePath => isRepartidor ? '/delivery/available' : '/home';

  @override
  List<Object?> get props => [id, nombre, email, rol];
}

class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}

class AuthSession extends Equatable {
  const AuthSession({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AuthUser user;

  @override
  List<Object?> get props => [tokens, user];
}

/// Perfil del usuario autenticado con los datos que devuelve
/// `GET /users/profile` (04 §4.1). El email es de solo lectura en la app
/// (07.1 SCR-PROF-02), por eso no se considera editable.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.creadoEn,
    this.ultimoLogin,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? telefono;
  final DateTime? creadoEn;
  final DateTime? ultimoLogin;

  @override
  List<Object?> get props => [
    id,
    nombre,
    email,
    rol,
    telefono,
    creadoEn,
    ultimoLogin,
  ];
}

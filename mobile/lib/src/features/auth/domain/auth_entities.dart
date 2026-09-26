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

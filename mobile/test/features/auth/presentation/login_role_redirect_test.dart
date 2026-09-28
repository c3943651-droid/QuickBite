import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';

/// Un repartidor que entra a la app debe caer en su propio shell, no en el
/// catálogo de cliente. 07.1 SCR-AUTH-02 fija la salida del login como
/// "redirección según rol" y `homeFor` ya conoce esa regla; lo que faltaba era
/// que el login la usara en lugar de hardcodear `/home`.
AuthSession sessionDe(String rol) => AuthSession(
  tokens: const AuthTokens(
    accessToken: 'a',
    refreshToken: 'r',
    expiresIn: 3600,
  ),
  user: AuthUser(id: '1', nombre: 'Ana', email: 'ana@quickbite.mx', rol: rol),
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  final AuthSession? session;
  final List<({String email, String password})> logins = [];
  StoredSession? persisted;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    logins.add((email: email, password: password));
    return session ?? sessionDe('cliente');
  }

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {}

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<UserProfile> fetchProfile() async => const UserProfile(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  );

  @override
  Future<UserProfile> updateProfile({String? nombre, String? telefono}) async =>
      UserProfile(
        id: '33333333-3333-3333-3333-333333333333',
        nombre: nombre ?? 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        rol: 'cliente',
        telefono: telefono,
      );

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async =>
      session?.tokens ??
      const AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600);

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession value) async {
    persisted = StoredSession(
      accessToken: value.tokens.accessToken,
      refreshToken: value.tokens.refreshToken,
      expiresIn: value.tokens.expiresIn,
    );
  }
}

void main() {
  group('La ruta de inicio depende del rol (07.1 SCR-AUTH-02)', () {
    test('un cliente entra al catálogo', () {
      expect(sessionDe('cliente').user.homePath, '/home');
    });

    test('un repartidor entra a pedidos disponibles', () {
      expect(sessionDe('repartidor').user.homePath, '/delivery/available');
    });

    test('un administrador no tiene shell propio y entra como cliente', () {
      expect(sessionDe('administrador').user.homePath, '/home');
    });

    test('el router usa la misma regla que la entidad', () {
      for (final rol in ['cliente', 'repartidor', 'administrador']) {
        expect(
          homeFor(sessionDe(rol)),
          sessionDe(rol).user.homePath,
          reason: rol,
        );
      }
    });
  });

  group('LoginScreen envía al shell del rol', () {
    Future<void> pumpLogin(
      WidgetTester tester, {
      required AuthSession session,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(session: session),
          ),
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
      );
      addTearDown(container.dispose);

      final router = createRouter(() => container.read(sessionProvider.future));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
    }

    testWidgets('un repartidor aterriza en pedidos disponibles', (
      tester,
    ) async {
      await pumpLogin(tester, session: sessionDe('repartidor'));

      expect(find.text('Pedidos disponibles'), findsOneWidget);
      expect(
        find.text('Tacos al pastor'),
        findsNothing,
        reason: 'el repartidor no debe ver el catálogo de cliente',
      );
    });

    testWidgets('un cliente aterriza en el catálogo', (tester) async {
      await pumpLogin(tester, session: sessionDe('cliente'));

      expect(find.text('Tacos al pastor'), findsOneWidget);
    });
  });
}

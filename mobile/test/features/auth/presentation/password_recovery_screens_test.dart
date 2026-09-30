import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.forgotError, this.resetError, this.registerError});

  final Object? forgotError;
  final Object? resetError;
  final Object? registerError;
  final List<String> forgotEmails = [];
  final List<({String token, String newPassword})> resets = [];

  @override
  Future<void> forgotPassword({required String email}) async {
    forgotEmails.add(email);
    if (forgotError != null) {
      throw forgotError!;
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resets.add((token: token, newPassword: newPassword));
    if (resetError != null) {
      throw resetError!;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    if (registerError != null) {
      throw registerError!;
    }
  }

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
      const AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600);

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession session) async {}
}

void main() {
  late FakeAuthRepository auth;

  setUp(() => auth = FakeAuthRepository());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Map<String, String> query = const {},
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() => container.read(sessionProvider.future));
    final uri = Uri(
      path: location,
      queryParameters: query.isEmpty ? null : query,
    );
    router.go(uri.toString());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enviar(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.ensureVisible(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
  }

  group('ForgotPasswordScreen (07.1 SCR-AUTH-04)', () {
    testWidgets('muestra el formulario de recuperación', (tester) async {
      await pumpAt(tester, '/forgot-password');

      expect(find.text('Recupera tu contraseña'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Enviar enlace'), findsOneWidget);
      expect(find.text('Volver a iniciar sesión'), findsOneWidget);
    });

    testWidgets('no llama a la API con un email inválido', (tester) async {
      await pumpAt(tester, '/forgot-password');

      await enviar(tester, 'no-es-un-email');

      expect(auth.forgotEmails, isEmpty);
      expect(find.textContaining('correo'), findsWidgets);
    });

    testWidgets('envía el email y confirma con el mensaje genérico', (
      tester,
    ) async {
      await pumpAt(tester, '/forgot-password');

      await enviar(tester, 'carlos@quickbite.mx');

      expect(auth.forgotEmails, ['carlos@quickbite.mx']);
      expect(
        find.text('Si el correo existe, recibirás un enlace'),
        findsOneWidget,
        reason: '05#D-04 exige el mismo mensaje exista o no el correo',
      );
    });

    testWidgets(
      'el mensaje es el mismo aunque el backend indique que el correo no existe',
      (tester) async {
        auth = FakeAuthRepository(
          forgotError: const ValidationException('El correo no existe.'),
        );
        await pumpAt(tester, '/forgot-password');

        await enviar(tester, 'desconocido@quickbite.mx');

        expect(
          find.text('Si el correo existe, recibirás un enlace'),
          findsOneWidget,
        );
        expect(find.textContaining('no existe'), findsNothing);
      },
    );

    testWidgets('muestra el error si la red falla', (tester) async {
      auth = FakeAuthRepository(forgotError: const NetworkException());
      await pumpAt(tester, '/forgot-password');

      await enviar(tester, 'carlos@quickbite.mx');

      expect(find.textContaining('conexión'), findsOneWidget);
    });

    testWidgets('vuelve al login', (tester) async {
      await pumpAt(tester, '/forgot-password');

      await tester.ensureVisible(find.text('Volver a iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver a iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen (07.1 SCR-AUTH-05)', () {
    testWidgets('pide contraseña y confirmación', (tester) async {
      await pumpAt(tester, '/reset-password', query: {'token': 'abc'});

      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('Restablecer contraseña'), findsOneWidget);
    });

    testWidgets('envía el token de la URL con la nueva contraseña', (
      tester,
    ) async {
      await pumpAt(tester, '/reset-password', query: {'token': 'abc'});

      await tester.enterText(find.byType(TextFormField).first, 'Password1!');
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tester.ensureVisible(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();

      expect(auth.resets.single.token, 'abc');
      expect(auth.resets.single.newPassword, 'Password1!');
    });

    testWidgets('exige que las contraseñas coincidan', (tester) async {
      await pumpAt(tester, '/reset-password', query: {'token': 'abc'});

      await tester.enterText(find.byType(TextFormField).first, 'Password1!');
      await tester.enterText(find.byType(TextFormField).last, 'Password2!');
      await tester.ensureVisible(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();

      expect(auth.resets, isEmpty);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('sin token en la URL ofrece pedir uno nuevo', (tester) async {
      await pumpAt(tester, '/reset-password');

      expect(find.textContaining('enlace'), findsWidgets);
      await tester.tap(find.text('Solicitar un nuevo enlace'));
      await tester.pumpAndSettle();

      expect(find.text('Recupera tu contraseña'), findsOneWidget);
    });

    testWidgets('un token inválido explica y ofrece pedir otro', (
      tester,
    ) async {
      auth = FakeAuthRepository(
        resetError: const ValidationException(
          'El enlace de recuperación es inválido o ha expirado.',
        ),
      );
      await pumpAt(tester, '/reset-password', query: {'token': 'caducado'});

      await tester.enterText(find.byType(TextFormField).first, 'Password1!');
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tester.ensureVisible(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();

      expect(find.textContaining('expirado'), findsOneWidget);
      expect(find.text('Solicitar un nuevo enlace'), findsOneWidget);
    });

    testWidgets('al restablecer vuelve al login', (tester) async {
      await pumpAt(tester, '/reset-password', query: {'token': 'abc'});

      await tester.enterText(find.byType(TextFormField).first, 'Password1!');
      await tester.enterText(find.byType(TextFormField).last, 'Password1!');
      await tester.ensureVisible(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });
  });

  group('Login → recuperación (07.1 SCR-AUTH-02/04)', () {
    testWidgets('el enlace de "¿Olvidaste tu contraseña?" abre la pantalla', (
      tester,
    ) async {
      await pumpAt(tester, '/login');

      await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.text('Recupera tu contraseña'), findsOneWidget);
      expect(find.textContaining('próximamente'), findsNothing);
    });
  });

  group('RegisterScreen email duplicado (04 §3.4 → 409)', () {
    testWidgets('informa que el correo ya está registrado', (tester) async {
      auth = FakeAuthRepository(
        registerError: const ConflictException('El correo ya existe.'),
      );
      await pumpAt(tester, '/register');

      await tester.enterText(find.byType(TextFormField).at(0), 'Carlos Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carlos@quickbite.mx',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');
      await tester.enterText(find.byType(TextFormField).at(4), 'Password1!');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.text('Registrarse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrarse'));
      await tester.pumpAndSettle();

      expect(find.text('El correo ya está registrado'), findsOneWidget);
      expect(find.text('Bienvenido de nuevo'), findsNothing);
    });
  });
}

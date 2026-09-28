import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_repository.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/notification_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/notification_fakes.dart';

class FakeProfileRepository implements AuthRepository {
  FakeProfileRepository({this.profile, this.fetchError, this.updateError});

  UserProfile? profile;
  final Object? fetchError;
  final Object? updateError;
  final List<({String? nombre, String? telefono})> updates = [];

  @override
  Future<UserProfile> fetchProfile() async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return profile ??
        const UserProfile(
          id: '33333333-3333-3333-3333-333333333333',
          nombre: 'Carlos Pérez',
          email: 'carlos@quickbite.mx',
          rol: 'cliente',
          telefono: '5512345678',
        );
  }

  @override
  Future<UserProfile> updateProfile({String? nombre, String? telefono}) async {
    updates.add((nombre: nombre, telefono: telefono));
    if (updateError != null) {
      throw updateError!;
    }
    profile = UserProfile(
      id: '33333333-3333-3333-3333-333333333333',
      nombre: nombre ?? profile?.nombre ?? 'Carlos Pérez',
      email: 'carlos@quickbite.mx',
      rol: profile?.rol ?? 'cliente',
      telefono: telefono,
    );
    return profile!;
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
  }) async {}

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

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
  late FakeProfileRepository auth;

  const cliente = AuthSession(
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
    user: AuthUser(
      id: '33333333-3333-3333-3333-333333333333',
      nombre: 'Carlos Pérez',
      email: 'carlos@quickbite.mx',
      rol: 'cliente',
    ),
  );

  const repartidor = AuthSession(
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
    user: AuthUser(
      id: '44444444-4444-4444-4444-444444444444',
      nombre: 'Luis García',
      email: 'luis@quickbite.mx',
      rol: 'repartidor',
    ),
  );

  setUp(() => auth = FakeProfileRepository());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    AuthSession session = cliente,
    NotificationRepository? notificaciones,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        if (notificaciones != null)
          notificationRepositoryProvider.overrideWithValue(notificaciones),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => session);
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProfileScreen (07.1 SCR-PROF-01)', () {
    testWidgets('muestra el encabezado con nombre, email y teléfono', (
      tester,
    ) async {
      await pumpAt(tester, '/profile');

      expect(find.text('Carlos Pérez'), findsOneWidget);
      expect(find.text('carlos@quickbite.mx'), findsOneWidget);
      expect(find.text('5512345678'), findsOneWidget);
    });

    testWidgets('lista las secciones del hub', (tester) async {
      await pumpAt(tester, '/profile');

      for (final label in [
        'Editar perfil',
        'Cambiar contraseña',
        'Mis direcciones',
        'Notificaciones',
        'Apariencia',
        'Idioma y región',
        'Privacidad',
        'Ayuda y soporte',
        'Acerca de',
        'Avanzado',
        'Eliminar cuenta',
        'Cerrar sesión',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'falta $label');
      }
    });

    testWidgets('la fila Notificaciones abre la bandeja y muestra el badge', (
      tester,
    ) async {
      final notificaciones = FakeNotificationRepository(
        notificaciones: [
          Notificacion(
            id: 'n1',
            tipo: TipoNotificacion.pedidoNuevo,
            titulo: 'Pedido recibido',
            mensaje: 'Estamos preparando tu pedido.',
            creadoEn: DateTime(2026, 9, 27, 15),
          ),
          Notificacion(
            id: 'n2',
            tipo: TipoNotificacion.sistema,
            titulo: 'Mantenimiento',
            mensaje: 'Domingo de mantenimiento.',
            leido: true,
            creadoEn: DateTime(2026, 9, 26, 10),
          ),
        ],
      );
      await pumpAt(tester, '/profile', notificaciones: notificaciones);

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido recibido'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
    });

    testWidgets('un repartidor no ve la fila de direcciones', (tester) async {
      auth = FakeProfileRepository(
        profile: const UserProfile(
          id: '44444444-4444-4444-4444-444444444444',
          nombre: 'Luis García',
          email: 'luis@quickbite.mx',
          rol: 'repartidor',
        ),
      );
      await pumpAt(tester, '/profile', session: repartidor);

      expect(find.text('Luis García'), findsOneWidget);
      expect(
        find.text('Mis direcciones'),
        findsNothing,
        reason: '07.1 SCR-PROF-01 oculta direcciones para repartidor',
      );
      expect(find.text('Editar perfil'), findsOneWidget);
    });

    testWidgets('el error de carga ofrece reintentar', (tester) async {
      auth = FakeProfileRepository(fetchError: const NetworkException());
      await pumpAt(tester, '/profile');

      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('EditProfileScreen (07.1 SCR-PROF-02)', () {
    testWidgets('precarga los datos actuales y el email bloqueado', (
      tester,
    ) async {
      await pumpAt(tester, '/profile/edit');

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Carlos Pérez'), findsOneWidget);
      expect(find.text('5512345678'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'carlos@quickbite.mx'),
        findsOneWidget,
      );
    });

    testWidgets('exige un nombre válido antes de enviar', (tester) async {
      await pumpAt(tester, '/profile/edit');

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('El nombre es obligatorio.'), findsOneWidget);
      expect(auth.updates, isEmpty);
    });

    testWidgets('guarda y vuelve al hub', (tester) async {
      await pumpAt(tester, '/profile/edit');

      await tester.enterText(
        find.byType(TextFormField).first,
        'Carlos P. Actualizado',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '55 9999 0000');
      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(auth.updates.single.nombre, 'Carlos P. Actualizado');
      expect(auth.updates.single.telefono, '55 9999 0000');
      expect(find.text('Mis direcciones'), findsOneWidget);
    });

    testWidgets('un fallo del backend no navega', (tester) async {
      auth = FakeProfileRepository(updateError: const ServerException());
      await pumpAt(tester, '/profile/edit');

      await tester.ensureVisible(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(find.text('Mis direcciones'), findsNothing);
    });
  });
}

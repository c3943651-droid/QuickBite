import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/images/seleccion_imagen.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/delivery_repository.dart';
import 'package:quickbite_mobile/src/features/delivery/presentation/delivery_providers.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
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
  Object? fetchError;

  /// Veces que se pidió el perfil: sirve para comprobar que "Reintentar" vuelve
  /// a consultar en vez de solo repintar.
  int fetchCalls = 0;
  final Object? updateError;
  final List<({String? nombre, String? telefono})> updates = [];

  @override
  Future<UserProfile> fetchProfile() async {
    fetchCalls++;
    final failure = fetchError;
    if (failure != null) {
      throw failure;
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
    SelectorImagen? selectorImagen,
    DeliveryRepository? delivery,
    bool rapido = false,
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
        if (selectorImagen != null)
          selectorImagenProvider.overrideWithValue(selectorImagen),
        if (delivery != null)
          deliveryRepositoryProvider.overrideWithValue(delivery),
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
    // `rapido` avanza solo un par de frames: es lo que hace falta para ver el
    // estado en el que *cae* la pantalla, sin darle tiempo a que riverpod
    // agote sus reintentos automáticos y termine mostrando el error igual.
    if (rapido) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      return;
    }
    await tester.pumpAndSettle();
  }

  group('ProfileScreen estados de carga y error (SCR-PROF-01)', () {
    testWidgets('un fallo de la API muestra el error, no un spinner eterno', (
      tester,
    ) async {
      auth.fetchError = const ServerException();

      await pumpAt(
        tester,
        '/profile',
        notificaciones: FakeNotificationRepository(),
        rapido: true,
      );

      // Riverpod 3 reintenta solo: sin `noAutoRetry` la pantalla vuelve a
      // "cargando" y el usuario ve un spinner en vez del error, sin poder
      // hacer nada hasta que se agoten los reintentos.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('reintentar vuelve a pedir el perfil', (tester) async {
      auth.fetchError = const ServerException();
      await pumpAt(
        tester,
        '/profile',
        notificaciones: FakeNotificationRepository(),
      );
      final llamadasAntes = auth.fetchCalls;

      auth.fetchError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.fetchCalls, greaterThan(llamadasAntes));
      expect(find.text('Carlos Pérez'), findsOneWidget);
    });

    testWidgets('un perfil con nombre vacío no rompe el encabezado', (
      tester,
    ) async {
      auth.profile = const UserProfile(
        id: '33333333-3333-3333-3333-333333333333',
        nombre: '',
        email: '',
        rol: 'cliente',
      );

      await pumpAt(tester, '/profile');

      // Sin nombre la pantalla sigue siendo usable: no hay un hueco en blanco
      // ni un error rojo en el AppBar.
      expect(find.byType(ErrorStateView), findsNothing);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('si el perfil no trae rol, se usan las secciones del cliente', (
      tester,
    ) async {
      auth.profile = const UserProfile(
        id: '33333333-3333-3333-3333-333333333333',
        nombre: 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        rol: '',
      );

      await pumpAt(tester, '/profile');

      // La sesión sí conoce el rol (es lo que usa el guard): si el perfil
      // llega sin él, se cae al de la sesión y no a un reparto imposible.
      expect(find.text('Mis direcciones'), findsOneWidget);
    });

    testWidgets('un teléfono vacío no deja una línea en blanco', (
      tester,
    ) async {
      auth.profile = const UserProfile(
        id: '33333333-3333-3333-3333-333333333333',
        nombre: 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        rol: 'cliente',
        telefono: '',
      );

      await pumpAt(tester, '/profile');

      expect(find.text(''), findsNothing);
    });
  });

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
        'Sesiones activas',
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

    testWidgets('el error de carga usa ErrorStateView con mensaje del error', (
      tester,
    ) async {
      auth = FakeProfileRepository(fetchError: const NetworkException());
      await pumpAt(tester, '/profile');

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(
        find.text(
          'No hay conexión con el servidor. Verifica tu red e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('la fila Mis direcciones navega a /addresses', (tester) async {
      await pumpAt(tester, '/profile');

      await tester.tap(find.text('Mis direcciones'));
      await tester.pumpAndSettle();

      expect(find.text('Agregar dirección'), findsOneWidget);
    });

    testWidgets('la fila Preferencias de notificaciones navega a la pantalla', (
      tester,
    ) async {
      await pumpAt(tester, '/profile');

      await tester.tap(find.text('Preferencias de notificaciones'));
      await tester.pumpAndSettle();

      expect(find.text('Preferencias de notificaciones'), findsOneWidget);
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

    testWidgets('elegir imagen abre el selector y previsualiza el archivo', (
      tester,
    ) async {
      final selector = FakeSelectorImagen('/tmp/avatar.jpg');
      await pumpAt(tester, '/profile/edit', selectorImagen: selector);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Cámara'), findsOneWidget);
      await tester.tap(find.text('Galería'));
      await tester.pumpAndSettle();

      expect(selector.origenes, [OrigenImagen.galeria]);
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isNotNull);
    });

    testWidgets('cancelar el selector deja el avatar como estaba', (
      tester,
    ) async {
      final selector = FakeSelectorImagen(null);
      await pumpAt(tester, '/profile/edit', selectorImagen: selector);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isNull);
      expect(avatar.child, isA<Icon>());
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

    testWidgets('un nombre con solo espacios se rechaza', (tester) async {
      await pumpAt(tester, '/profile/edit');

      await tester.enterText(find.byType(TextFormField).first, '   ');
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

    testWidgets('el repartidor ve sus secciones y el cliente no', (
      tester,
    ) async {
      // El rol de la pantalla sale del perfil que devuelve la API, no de la
      // sesión: por eso el doble hay que ajustarlo, no solo la sesión.
      auth.profile = const UserProfile(
        id: '44444444-4444-4444-4444-444444444444',
        nombre: 'Luis García',
        email: 'luis@quickbite.mx',
        rol: 'repartidor',
      );
      await pumpAt(tester, '/profile', session: repartidor);

      expect(find.text('Mis estadísticas'), findsOneWidget);
      expect(find.text('Disponibilidad'), findsOneWidget);
      expect(find.text('Mis direcciones'), findsNothing);
    });

    testWidgets('el repartidor abre sus estadísticas', (tester) async {
      auth.profile = const UserProfile(
        id: '44444444-4444-4444-4444-444444444444',
        nombre: 'Luis García',
        email: 'luis@quickbite.mx',
        rol: 'repartidor',
      );
      await pumpAt(tester, '/profile', session: repartidor);

      await tester.tap(find.text('Mis estadísticas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(AppBar, 'Mis estadísticas'), findsOneWidget);
    });

    testWidgets('el repartidor abre su disponibilidad', (tester) async {
      auth.profile = const UserProfile(
        id: '44444444-4444-4444-4444-444444444444',
        nombre: 'Luis García',
        email: 'luis@quickbite.mx',
        rol: 'repartidor',
      );
      await pumpAt(tester, '/profile', session: repartidor);

      await tester.tap(find.text('Disponibilidad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(AppBar, 'Disponibilidad'), findsOneWidget);
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

class FakeSelectorImagen implements SelectorImagen {
  FakeSelectorImagen(this.ruta);

  final String? ruta;
  final List<OrigenImagen> origenes = [];

  @override
  Future<String?> seleccionar(OrigenImagen origen) async {
    origenes.add(origen);
    return ruta;
  }
}

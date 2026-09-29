import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/change_password_screen.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/security_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/security_screen.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/sessions_screen.dart';

import '../../../support/profile_fakes.dart';
import '../../../support/router_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSeguridadRepository repository;

  setUp(() => repository = FakeSeguridadRepository());

  /// Monta la pantalla pedida dentro de un `MaterialApp` con `Navigator` real:
  /// las tres pantallas usan `context.pop()` y `ConfirmDialog`, que necesitan un
  /// `Navigator` del que dependan. Las rutas son las reales de 07.1 para que
  /// `context.push` no apunte a un destino inexistente.
  Future<void> pumpPantalla(
    WidgetTester tester,
    Widget pantalla, {
    required String rutaInicial,
  }) async {
    // Sin esto el ListView solo construye lo que cabe en la superficie de test
    // por defecto y el formulario de contraseña queda sin campos a medias.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // La pantalla que se prueba se monta en la ruta pedida; las demás quedan
    // registradas para que la navegación dentro del módulo funcione.
    final pantallas = <String, Widget>{
      '/profile/security': const SecurityScreen(),
      '/profile/security/password': const ChangePasswordScreen(),
      '/profile/security/sessions': const SessionsScreen(),
    };
    pantallas[rutaInicial] = pantalla;

    final router = GoRouter(
      initialLocation: rutaInicial,
      routes: [
        GoRoute(
          path: '/profile/security',
          builder: (context, state) => pantallas['/profile/security']!,
          routes: [
            GoRoute(
              path: 'password',
              builder: (context, state) =>
                  pantallas['/profile/security/password']!,
            ),
            GoRoute(
              path: 'sessions',
              builder: (context, state) =>
                  pantallas['/profile/security/sessions']!,
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          seguridadRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// El icono de un requisito es hermano de su texto dentro de la fila, así
  /// que se busca desde la fila que lo contiene y no desde el `Text`.
  Finder requisitoCumplido(String etiqueta) => find.descendant(
    of: find.ancestor(of: find.text(etiqueta), matching: find.byType(Row)),
    matching: find.byIcon(Icons.check_circle),
  );

  Future<void> pumpSeguridad(WidgetTester tester) => pumpPantalla(
    tester,
    const SecurityScreen(),
    rutaInicial: '/profile/security',
  );

  Future<void> pumpSesiones(WidgetTester tester) => pumpPantalla(
    tester,
    const SessionsScreen(),
    rutaInicial: '/profile/security/sessions',
  );

  Future<void> pumpCambio(WidgetTester tester) => pumpPantalla(
    tester,
    const ChangePasswordScreen(),
    rutaInicial: '/profile/security/password',
  );

  group('SecurityScreen (07.1 SCR-PROF-03)', () {
    testWidgets('es el hub con cambiar contraseña y sesiones activas', (
      tester,
    ) async {
      await pumpSeguridad(tester);

      expect(find.text('Cambiar contraseña'), findsOneWidget);
      expect(find.text('Sesiones activas'), findsOneWidget);
    });

    testWidgets('muestra cuántas sesiones hay activas', (tester) async {
      repository.sesiones = [sesion(esActual: true), sesion(id: 'sesion-2')];

      await pumpSeguridad(tester);
      await tester.pumpAndSettle();

      expect(find.text('2 sesiones activas'), findsOneWidget);
    });

    testWidgets('no inventa un contador cuando la lista no pudo cargarse', (
      tester,
    ) async {
      repository.error = Exception('boom');

      await pumpSeguridad(tester);
      await tester.pumpAndSettle();

      expect(find.text('2 sesiones activas'), findsNothing);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('la fila de contraseña navega a SCR-PROF-04', (tester) async {
      await pumpSeguridad(tester);
      final router = GoRouter.of(tester.element(find.byType(SecurityScreen)));

      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/profile/security/password');
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('la fila de sesiones navega al listado', (tester) async {
      await pumpSeguridad(tester);
      final router = GoRouter.of(tester.element(find.byType(SecurityScreen)));

      await tester.tap(find.text('Sesiones activas'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/profile/security/sessions');
      expect(find.byType(SessionsScreen), findsOneWidget);
    });
  });

  group('SessionsScreen (07.1 SCR-PROF-05)', () {
    testWidgets('lista IP, agente y fechas de cada sesión', (tester) async {
      repository.sesiones = [sesion(esActual: true)];

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      expect(find.text('203.0.113.7'), findsOneWidget);
      expect(find.text('Chrome 141 / Android'), findsOneWidget);
    });

    testWidgets('marca la sesión actual y no ofrece revocarla', (tester) async {
      repository.sesiones = [sesion(esActual: true), sesion(id: 'sesion-2')];

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      expect(find.text('Esta sesión'), findsOneWidget);
      expect(find.text('Revocar'), findsOneWidget);
    });

    testWidgets('revocar pide confirmación y quita la sesión de la lista', (
      tester,
    ) async {
      repository.sesiones = [sesion(id: 'sesion-2')];

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Revocar esta sesión?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Revocar'));
      await tester.pumpAndSettle();

      expect(repository.revocadas, ['sesion-2']);
      expect(find.text('Chrome 141 / Android'), findsNothing);
    });

    testWidgets('cancelar la confirmación no revoca nada', (tester) async {
      repository.sesiones = [sesion(id: 'sesion-2')];

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Volver'));
      await tester.pumpAndSettle();

      expect(repository.revocadas, isEmpty);
      expect(find.text('Chrome 141 / Android'), findsOneWidget);
    });

    testWidgets('si revocar falla avisa y deja la sesión en la lista', (
      tester,
    ) async {
      repository.sesiones = [sesion(id: 'sesion-2')];
      repository.revokeError = Exception('boom');

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revocar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Revocar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo revocar la sesión'), findsOneWidget);
      expect(find.text('Sesión revocada'), findsNothing);
      expect(find.text('Chrome 141 / Android'), findsOneWidget);
    });

    testWidgets('sin sesiones muestra el estado vacío', (tester) async {
      repository.sesiones = [];

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      expect(find.text('No hay sesiones activas'), findsOneWidget);
    });

    testWidgets('un error al listar ofrece reintentar', (tester) async {
      repository.error = Exception('boom');

      await pumpSesiones(tester);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No pudimos cargar tus sesiones'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('ChangePasswordScreen (07.1 SCR-PROF-04)', () {
    testWidgets('pide la actual, la nueva y su confirmación', (tester) async {
      await pumpCambio(tester);

      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
    });

    testWidgets('los requisitos se marcan en vivo al escribir', (tester) async {
      await pumpCambio(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        'abc',
      );
      await tester.pump();
      expect(requisitoCumplido('Mínimo 8 caracteres'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        'Nueva23#',
      );
      await tester.pump();
      expect(requisitoCumplido('Mínimo 8 caracteres'), findsOneWidget);
    });

    testWidgets('una confirmación distinta de la nueva no envía nada', (
      tester,
    ) async {
      await pumpCambio(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña actual'),
        'Vieja1!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        'Nueva23#',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña'),
        'Otra3#',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(repository.cambios, isEmpty);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('guarda y vuelve a seguridad con aviso', (tester) async {
      await pumpCambio(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña actual'),
        'Vieja1!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        'Nueva23#',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña'),
        'Nueva23#',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(repository.cambios, [(actual: 'Vieja1!', nueva: 'Nueva23#')]);
      expect(find.text('Contraseña actualizada'), findsOneWidget);
    });

    testWidgets('la contraseña actual incorrecta se explica sin salir', (
      tester,
    ) async {
      repository.error = passwordIncorrecto;

      await pumpCambio(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña actual'),
        'Mal1!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nueva contraseña'),
        'Nueva23#',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña'),
        'Nueva23#',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('La contraseña actual es incorrecta.'), findsOneWidget);
    });
  });
}

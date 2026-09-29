import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/core/external/enlaces_externos.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/about_screen.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/delete_account_screen.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/help_screen.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/privacy_screen.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_launcher.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/router_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExternalLauncher launcher;

  Future<void> pump(
    WidgetTester tester,
    Widget pantalla, {
    String ruta = '/profile/privacy',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    PackageInfo.setMockInitialValues(
      appName: 'QuickBite',
      packageName: 'mx.quickbite.app',
      version: '1.0.0',
      buildNumber: '42',
      buildSignature: '',
    );

    launcher = FakeExternalLauncher();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(prefs),
        externalLauncherProvider.overrideWithValue(launcher),
        // Sin esto la pantalla de eliminación pediría el perfil por red.
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: '1',
            nombre: 'Carlos',
            email: 'carlos@quickbite.mx',
            rol: 'cliente',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: ruta,
      routes: [
        GoRoute(path: ruta, builder: (context, state) => pantalla),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PrivacyScreen (07.1 SCR-PROF-11)', () {
    testWidgets('lista política, términos, permisos y uso de datos', (
      tester,
    ) async {
      await pump(tester, const PrivacyScreen());

      for (final etiqueta in [
        'Política de privacidad',
        'Términos de uso',
        'Permisos de la app',
        'Uso de datos',
      ]) {
        expect(find.text(etiqueta), findsOneWidget, reason: 'falta $etiqueta');
      }
    });

    testWidgets('los permisos de la app se nombran uno a uno', (tester) async {
      await pump(tester, const PrivacyScreen());

      expect(find.text('Cámara'), findsOneWidget);
      expect(find.textContaining('Almacenamiento'), findsOneWidget);
    });

    testWidgets('abrir la política pide el documento al navegador', (
      tester,
    ) async {
      await pump(tester, const PrivacyScreen());

      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();

      expect(launcher.uris.single.path, '/legal/privacidad');
      expect(launcher.uris.single.origin, 'https://test.mx');
    });

    testWidgets('si no hay navegador avisa en vez de fallar en silencio', (
      tester,
    ) async {
      await pump(tester, const PrivacyScreen());
      launcher.puedeAbrir = false;

      await tester.tap(find.text('Términos de uso'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo abrir'), findsOneWidget);
    });
  });

  group('HelpScreen (07.1 SCR-PROF-12)', () {
    testWidgets('muestra soporte, reportar un problema y la guía', (
      tester,
    ) async {
      await pump(
        tester,
        const HelpScreen(),
        ruta: '/profile/help',
      );

      for (final etiqueta in [
        'Contactar soporte',
        'Reportar un problema',
        'Guía rápida',
      ]) {
        expect(find.text(etiqueta), findsOneWidget, reason: 'falta $etiqueta');
      }
    });

    testWidgets('las preguntas frecuentes se expanden y se contraen', (
      tester,
    ) async {
      await pump(tester, const HelpScreen(), ruta: '/profile/help');

      const respuesta = 'Abre Pedidos, elige una dirección guardada';
      expect(find.textContaining('domicilio'), findsOneWidget);
      expect(find.textContaining(respuesta), findsNothing);

      await tester.tap(find.textContaining('domicilio'));
      await tester.pumpAndSettle();
      expect(find.textContaining(respuesta), findsOneWidget);

      await tester.tap(find.textContaining('domicilio'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(respuesta),
        findsNothing,
        reason: 'volver a tocar la misma pregunta debe contraerla',
      );
    });

    testWidgets('contactar soporte abre el correo con asunto y cuerpo', (
      tester,
    ) async {
      await pump(tester, const HelpScreen(), ruta: '/profile/help');

      await tester.tap(find.text('Contactar soporte'));
      await tester.pumpAndSettle();

      final uri = launcher.uris.single;
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'soporte@test.mx');
      expect(uri.queryParameters['subject'], isNotEmpty);
    });
  });

  group('AboutScreen (07.1 SCR-PROF-13)', () {
    testWidgets('muestra nombre, versión y build', (tester) async {
      await pump(tester, const AboutScreen(), ruta: '/profile/about');

      expect(find.text('QuickBite'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
      expect(find.textContaining('42'), findsOneWidget);
    });

    testWidgets('las licencias se abren en el navegador', (tester) async {
      await pump(tester, const AboutScreen(), ruta: '/profile/about');

      await tester.tap(find.text('Licencias de código abierto'));
      await tester.pumpAndSettle();

      expect(launcher.uris.single.path, '/legal/licencias');
    });

    testWidgets('términos y privacidad están a un toque', (tester) async {
      await pump(tester, const AboutScreen(), ruta: '/profile/about');

      await tester.tap(find.text('Términos de uso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();

      expect(
        launcher.uris.map((u) => u.path),
        containsAll(['/legal/terminos', '/legal/privacidad']),
      );
    });
  });

  group('DeleteAccountScreen (07.1 SCR-PROF-15)', () {
    testWidgets('advierte de que el proceso es manual y da los pasos', (
      tester,
    ) async {
      await pump(
        tester,
        const DeleteAccountScreen(),
        ruta: '/profile/delete-account',
      );

      expect(find.textContaining('manual'), findsWidgets);
      expect(find.textContaining('1.'), findsOneWidget);
      expect(find.textContaining('2.'), findsOneWidget);
      expect(find.textContaining('3.'), findsOneWidget);
    });

    testWidgets('el botón abre el correo con los datos del usuario', (
      tester,
    ) async {
      await pump(
        tester,
        const DeleteAccountScreen(),
        ruta: '/profile/delete-account',
      );

      await tester.tap(find.text('Contactar para eliminar mi cuenta'));
      await tester.pumpAndSettle();

      final uri = launcher.uris.single;
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'soporte@test.mx');
      expect(uri.queryParameters['subject'], contains('eliminación'));
      // El cuerpo lleva los datos del usuario que ya tenía la pantalla, para
      // que no tenga que escribirlos otra vez.
      expect(uri.queryParameters['body'], contains('carlos@quickbite.mx'));
      expect(uri.queryParameters['body'], contains('Carlos'));
    });
  });
}

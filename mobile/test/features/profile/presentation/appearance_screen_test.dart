import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_apariencia.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/apariencia_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/appearance_screen.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpApariencia(
    WidgetTester tester, {
    Map<String, Object> guardadas = const {},
  }) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
    // La pantalla es una lista larga: sin una superficie alta el `ListView` solo
    // construye la primera sección y las demás no llegan a existir.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile/appearance',
      routes: [
        GoRoute(
          path: '/profile/appearance',
          builder: (context, state) => const AppearanceScreen(),
        ),
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

  PreferenciasApariencia leer() =>
      container.read(aparienciaProvider).requireValue;

  group('AppearanceScreen (07.1 SCR-PROF-09)', () {
    testWidgets('muestra las cinco secciones con sus opciones', (tester) async {
      await pumpApariencia(tester);

      for (final etiqueta in [
        'Tema',
        'Tamaño de texto',
        'Contraste',
        'Reducir animaciones',
        'Modo daltónico',
        'Claro',
        'Oscuro',
        'Sistema',
        'Pequeño',
        'Normal',
        'Grande',
        'Muy grande',
        'Alto contraste',
        'Deuteranopía',
        'Protanopía',
        'Tritanopía',
      ]) {
        expect(find.text(etiqueta), findsWidgets, reason: 'falta $etiqueta');
      }
    });

    testWidgets('el contraste se ofrece como interruptor, no como lista', (
      tester,
    ) async {
      await pumpApariencia(tester);

      // `Contraste.normal` y `TamanoTexto.normal` comparten etiqueta ("Normal"):
      // el contraste se decide con un interruptor para no duplicar la opción.
      expect(
        find.widgetWithText(SwitchListTile, 'Alto contraste'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SwitchListTile, 'Reducir animaciones'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(RadioListTile<TamanoTexto>, 'Normal'),
        findsOneWidget,
      );
    });

    testWidgets('arranca con los valores por defecto', (tester) async {
      await pumpApariencia(tester);

      expect(leer().tema, TemaApp.sistema);
      expect(leer().tamanoTexto, TamanoTexto.normal);
      expect(leer().contraste, Contraste.normal);
      expect(leer().reducirAnimaciones, isFalse);
      expect(leer().modoDaltonismo, ModoDaltonismo.normal);
    });

    testWidgets('muestra lo que había quedado guardado', (tester) async {
      await pumpApariencia(
        tester,
        guardadas: {
          'quickbite_apar_tema': 'oscuro',
          'quickbite_apar_tamano': 'muyGrande',
          'quickbite_apar_contraste': 'alto',
          'quickbite_apar_animaciones': true,
          'quickbite_apar_daltonismo': 'tritanopia',
        },
      );

      expect(leer().tema, TemaApp.oscuro);
      expect(leer().tamanoTexto, TamanoTexto.muyGrande);
      expect(leer().contraste, Contraste.alto);
      expect(leer().reducirAnimaciones, isTrue);
      expect(leer().modoDaltonismo, ModoDaltonismo.tritanopia);
    });

    testWidgets('elegir tema oscuro se guarda en el dispositivo', (
      tester,
    ) async {
      await pumpApariencia(tester);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(leer().tema, TemaApp.oscuro);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('quickbite_apar_tema'),
        'oscuro',
      );
    });

    testWidgets('elegir un tamaño de texto grande se guarda', (tester) async {
      await pumpApariencia(tester);

      await tester.tap(find.text('Muy grande'));
      await tester.pumpAndSettle();

      expect(leer().tamanoTexto, TamanoTexto.muyGrande);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('quickbite_apar_tamano'),
        'muyGrande',
      );
    });

    testWidgets('activar alto contraste se guarda', (tester) async {
      await pumpApariencia(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Alto contraste'));
      await tester.pumpAndSettle();

      expect(leer().contraste, Contraste.alto);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('quickbite_apar_contraste'),
        'alto',
      );
    });

    testWidgets('reducir animaciones se guarda', (tester) async {
      await pumpApariencia(tester);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Reducir animaciones'),
      );
      await tester.pumpAndSettle();

      expect(leer().reducirAnimaciones, isTrue);
    });

    testWidgets('elegir un modo daltónico se guarda', (tester) async {
      await pumpApariencia(tester);

      await tester.tap(find.text('Protanopía'));
      await tester.pumpAndSettle();

      expect(leer().modoDaltonismo, ModoDaltonismo.protanopia);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('quickbite_apar_daltonismo'),
        'protanopia',
      );
    });

    testWidgets('la moneda no aparece en apariencia: es de idioma y región', (
      tester,
    ) async {
      await pumpApariencia(tester);

      expect(find.textContaining('Moneda'), findsNothing);
    });
  });
}

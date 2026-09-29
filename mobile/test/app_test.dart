import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/app.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required Map<String, Object> guardadas,
    Brightness brillo = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(platformBrightness: brillo),
          child: const QuickBiteApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('QuickBiteApp aplica las preferencias de apariencia (07.1 SCR-PROF-09)', () {
    testWidgets('con "Oscuro" usa el tema oscuro aunque el sistema esté en claro', (
      tester,
    ) async {
      await pumpApp(tester, guardadas: {
        'quickbite_apar_tema': 'oscuro',
      });

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(
        app.darkTheme!.colorScheme.brightness,
        Brightness.dark,
        reason: 'el tema activo debe ser el oscuro elegido por el usuario',
      );
    });

    testWidgets('con "Sistema" sigue al sistema operativo', (tester) async {
      await pumpApp(
        tester,
        guardadas: const {},
        brillo: Brightness.dark,
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(app.darkTheme!.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('"Muy grande" multiplica la escala de texto del sistema', (
      tester,
    ) async {
      await pumpApp(tester, guardadas: {
        'quickbite_apar_tamano': 'muyGrande',
      });

      // El `builder` de MaterialApp queda por debajo de él, así que el
      // `MediaQuery` con los ajustes de la app se lee desde una pantalla.
      final media = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      expect(media.textScaler.scale(10), closeTo(13, 0.001));
    });

    testWidgets('"Reducir animaciones" apaga las animaciones en toda la app', (
      tester,
    ) async {
      await pumpApp(tester, guardadas: {
        'quickbite_apar_animaciones': true,
      });

      final media = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      expect(media.disableAnimations, isTrue);
    });

    testWidgets('el alto contraste llega al tema que se está usando', (
      tester,
    ) async {
      await pumpApp(tester, guardadas: {
        'quickbite_apar_contraste': 'alto',
      });

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.textTheme.bodyLarge?.color, Colors.black);
    });
  });
}

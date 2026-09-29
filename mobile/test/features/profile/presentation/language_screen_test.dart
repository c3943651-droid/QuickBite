import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_idioma.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/idioma_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/language_screen.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<void> pumpIdioma(
    WidgetTester tester, {
    Map<String, Object> guardadas = const {},
  }) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
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
      initialLocation: '/profile/language',
      routes: [
        GoRoute(
          path: '/profile/language',
          builder: (context, state) => const LanguageScreen(),
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

  PreferenciasIdioma leer() =>
      container.read(idiomaProvider).requireValue;

  group('LanguageScreen (07.1 SCR-PROF-10)', () {
    testWidgets('muestra idioma, fecha, hora y la moneda informativa', (
      tester,
    ) async {
      await pumpIdioma(tester);

      for (final etiqueta in [
        'Idioma',
        'Formato de fecha',
        'Formato de hora',
        'Moneda',
      ]) {
        expect(find.text(etiqueta), findsOneWidget, reason: 'falta $etiqueta');
      }
    });

    testWidgets('español es la única opción de idioma en v1.0', (tester) async {
      await pumpIdioma(tester);

      expect(find.text('Español'), findsOneWidget);
      expect(find.textContaining('único idioma'), findsOneWidget);
    });

    testWidgets('arranca con los formatos por defecto', (tester) async {
      await pumpIdioma(tester);

      expect(leer().idioma, IdiomaApp.espanol);
      expect(leer().formatoFecha, FormatoFecha.diaMesAno);
      expect(leer().formatoHora, FormatoHora.veinticuatro);
    });

    testWidgets('muestra lo que había quedado guardado', (tester) async {
      await pumpIdioma(tester, guardadas: {
        'quickbite_idioma_fecha': 'anoMesDia',
        'quickbite_idioma_hora': 'doce',
      });

      expect(leer().formatoFecha, FormatoFecha.anoMesDia);
      expect(leer().formatoHora, FormatoHora.doce);
    });

    testWidgets('elegir AAAA-MM-DD se guarda', (tester) async {
      await pumpIdioma(tester);

      await tester.tap(find.text('AAAA-MM-DD'));
      await tester.pumpAndSettle();

      expect(leer().formatoFecha, FormatoFecha.anoMesDia);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString('quickbite_idioma_fecha'),
        'anoMesDia',
      );
    });

    testWidgets('elegir 12 horas se guarda', (tester) async {
      await pumpIdioma(tester);

      await tester.tap(
        find.widgetWithText(RadioListTile<FormatoHora>, '12 horas'),
      );
      await tester.pumpAndSettle();

      expect(leer().formatoHora, FormatoHora.doce);
      expect(
        container.read(sharedPreferencesProvider).getString('quickbite_idioma_hora'),
        'doce',
      );
    });

    testWidgets('la moneda se informa pero no se puede cambiar', (tester) async {
      await pumpIdioma(tester);

      expect(find.textContaining('MXN'), findsOneWidget);
      expect(find.textContaining('fija'), findsOneWidget);
    });
  });
}

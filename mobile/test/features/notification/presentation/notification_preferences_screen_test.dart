// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_token_storage.dart';
import '../../../support/router_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPreferencias(
    WidgetTester tester, {
    Map<String, Object> guardadas = const {},
  }) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = InMemoryTokenStorage();
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => sessionFor('cliente'));
    addTearDown(router.dispose);
    router.go('/profile/notifications');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La frecuencia vive al final de una lista larga: se hace scroll hasta ella
  /// en vez de depender del tamaño de la ventana de prueba.
  Future<void> verFrecuencia(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('10 segundos'), 200);
    await tester.pumpAndSettle();
  }

  group('NotificationPreferencesScreen (07.1 SCR-PROF-08)', () {
    testWidgets('muestra los cinco tipos, sonido y vibración', (tester) async {
      await pumpPreferencias(tester);

      expect(find.text('Preferencias de notificaciones'), findsOneWidget);
      for (final etiqueta in [
        'Pedidos nuevos',
        'Cambios de estado',
        'Asignaciones',
        'Sistema',
        'Recordatorios',
        'Sonido',
        'Vibración',
      ]) {
        expect(find.text(etiqueta), findsOneWidget, reason: 'falta $etiqueta');
      }
      await verFrecuencia(tester);
      expect(find.text('Frecuencia de actualización'), findsOneWidget);
    });

    testWidgets('los cinco tipos arrancan encendidos', (tester) async {
      await pumpPreferencias(tester);

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches, hasLength(7));
      for (final tile in switches) {
        expect(
          tile.value,
          isTrue,
          reason: '${tile.title} debería estar activo',
        );
      }
    });

    testWidgets('apagar recordatorios persiste la preferencia', (tester) async {
      await pumpPreferencias(tester);

      await tester.tap(find.text('Recordatorios'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('quickbite_prefs_recordatorio'), isFalse);
    });

    testWidgets('apagar el sonido no toca la vibración', (tester) async {
      await pumpPreferencias(tester);

      await tester.tap(find.text('Sonido'));
      await tester.pumpAndSettle();

      final sonido = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Sonido'),
      );
      final vibracion = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Vibración'),
      );
      expect(sonido.value, isFalse);
      expect(vibracion.value, isTrue);
    });

    testWidgets('el selector ofrece 10 s, 30 s y 1 min', (tester) async {
      await pumpPreferencias(tester);
      await verFrecuencia(tester);

      expect(find.text('10 segundos'), findsOneWidget);
      expect(find.text('30 segundos'), findsOneWidget);
      expect(find.text('1 minuto'), findsOneWidget);
    });

    testWidgets('elegir 30 segundos guarda la frecuencia y marca el radio', (
      tester,
    ) async {
      await pumpPreferencias(tester);
      await verFrecuencia(tester);

      await tester.tap(find.text('30 segundos'));
      await tester.pumpAndSettle();

      final seleccion = tester
          .widget<RadioListTile<Duration>>(
            find.widgetWithText(RadioListTile<Duration>, '30 segundos'),
          )
          .groupValue;
      expect(seleccion, const Duration(seconds: 30));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('quickbite_prefs_intervalo_segundos'), 30);
    });

    testWidgets('la frecuencia guardada se refleja al abrir', (tester) async {
      await pumpPreferencias(
        tester,
        guardadas: {'quickbite_prefs_intervalo_segundos': 60},
      );
      await verFrecuencia(tester);

      final seleccion = tester
          .widget<RadioListTile<Duration>>(
            find.widgetWithText(RadioListTile<Duration>, '1 minuto'),
          )
          .groupValue;
      expect(seleccion, const Duration(minutes: 1));
    });

    testWidgets('un valor corrupto no rompe la pantalla', (tester) async {
      await pumpPreferencias(
        tester,
        guardadas: {'quickbite_prefs_intervalo_segundos': 'pronto'},
      );
      await verFrecuencia(tester);

      expect(find.text('Preferencias de actualización'), findsNothing);
      expect(find.text('Frecuencia de actualización'), findsOneWidget);
      final seleccion = tester
          .widget<RadioListTile<Duration>>(
            find.widgetWithText(RadioListTile<Duration>, '10 segundos'),
          )
          .groupValue;
      expect(seleccion, const Duration(seconds: 10));
    });

    testWidgets('la pantalla es alcanzable desde el hub de perfil', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final tokenStorage = InMemoryTokenStorage();
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          sharedPreferencesProvider.overrideWithValue(prefs),
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

      final router = createRouter(() async => sessionFor('cliente'));
      addTearDown(router.dispose);
      router.go('/profile');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preferencias de notificaciones'));
      await tester.pumpAndSettle();
      await verFrecuencia(tester);

      expect(find.text('Frecuencia de actualización'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_idioma.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/security_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/sessions_screen.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_token_storage.dart';
import '../../../support/profile_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSeguridadRepository repository;

  // La pantalla pinta en hora local, así que la prueba compara contra la misma
  // conversión: no puede depender del huso de la máquina.
  final creada = DateTime.utc(2026, 9, 28, 13, 5);
  final local = creada.toLocal();

  Future<void> pumpSesiones(
    WidgetTester tester, {
    Map<String, Object> guardadas = const {},
  }) async {
    SharedPreferences.setMockInitialValues(guardadas);
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeSeguridadRepository(sesiones: [sesion(creadoEn: creada)]);

    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(prefs),
        seguridadRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile/security/sessions',
      routes: [
        GoRoute(
          path: '/profile/security/sessions',
          builder: (context, state) => const SessionsScreen(),
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

  group('SessionsScreen usa los formatos regionales (07.1 SCR-PROF-10)', () {
    testWidgets('con AAAA-MM-DD y 12 horas pinta esa fecha y esa hora', (
      tester,
    ) async {
      await pumpSesiones(
        tester,
        guardadas: {
          'quickbite_idioma_fecha': 'anoMesDia',
          'quickbite_idioma_hora': 'doce',
        },
      );

      expect(
        find.textContaining(FormatoFecha.anoMesDia.formatear(local)),
        findsOneWidget,
      );
      expect(
        find.textContaining(FormatoHora.doce.formatear(local)),
        findsOneWidget,
      );
    });

    testWidgets('con DD/MM/AAAA y 24 horas pinta el formato español', (
      tester,
    ) async {
      await pumpSesiones(tester);

      expect(
        find.textContaining(FormatoFecha.diaMesAno.formatear(local)),
        findsOneWidget,
      );
      expect(
        find.textContaining(FormatoHora.veinticuatro.formatear(local)),
        findsOneWidget,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';

import '../../support/app_harness.dart';

/// 401 permanente dentro de la app (SCR-COM-03).
///
/// El flujo completo —interceptor, renovación fallida, limpieza de sesión y
/// redirect— se prueba aquí contra la app real. El test previo
/// (`session_expiry_test.dart`) aísla solo la reacción del router con una
/// sesión falsa, y por eso no detectó que al tocar Perfil la persona se quedaba
/// mirando un error con botón "Reintentar" en vez de volver al login.
void main() {
  void backendConSesionCaducada(AppHarness app) {
    app.http
      // Ni el perfil ni la renovación son aceptados: el token ya no vale.
      ..onError('GET', '/users/profile', statusCode: 401, body: {})
      ..onError('POST', '/auth/refresh', statusCode: 401, body: {})
      ..on('POST', '/auth/login', loginDe('cliente'))
      ..on('GET', '/products', pagina(const []))
      ..on('GET', '/categories', const []);
  }

  testWidgets(
    'un 401 permanente devuelve a /login en vez de quedarse en error',
    (tester) async {
      final app = await AppHarness.montar(
        tester,
        tokensIniciales: sesionGuardada,
      );
      backendConSesionCaducada(app);

      await asentar(tester);

      // La sesión no se restaura y la persona cae en el login, no en un error.
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.byType(ErrorStateView), findsNothing);
    },
  );

  testWidgets('al tocar Perfil con el refresh inválido, se vuelve al login', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);

    // 1. Login normal: la app entra a la sesión.
    app.http
      ..on('POST', '/auth/login', loginDe('cliente'))
      ..on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
        'telefono': '5512345678',
      })
      ..on('GET', '/products', pagina([producto()]))
      ..on('GET', '/categories', const [])
      ..on('GET', '/notifications', const []);

    await tester.enterText(
      find.byType(TextFormField).first,
      'carlos@quickbite.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await asentar(tester);
    expect(find.text('Catálogo'), findsWidgets);

    // 2. El servidor revoca la sesión entre medias: ahora todo es 401.
    app.http
      ..onError('GET', '/users/profile', statusCode: 401, body: {})
      ..onError('POST', '/auth/refresh', statusCode: 401, body: {});

    await tester.tap(find.text('Perfil'));
    await asentar(tester);

    // 3. Ni pantalla de error atascada ni spinner: el login, con el aviso.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(ErrorStateView), findsNothing);
    expect(find.text('Tu sesión ha expirado'), findsOneWidget);
  });

  testWidgets('la sesión caducada borra los tokens locales', (tester) async {
    final app = await AppHarness.montar(
      tester,
      tokensIniciales: sesionGuardada,
    );
    backendConSesionCaducada(app);

    await asentar(tester);

    // Sin tokens, un reinicio posterior no vuelve a intentar usar la sesión.
    expect(app.tokens.accessToken, isNull);
    expect(app.tokens.refreshToken, isNull);
  });

  testWidgets('volver a entrar después de expirar no repite el aviso', (
    tester,
  ) async {
    final app = await AppHarness.montar(
      tester,
      tokensIniciales: sesionGuardada,
    );
    backendConSesionCaducada(app);
    await asentar(tester);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Segundo intento: ahora el servidor sí acepta el login.
    app.http
      ..on('POST', '/auth/login', loginDe('cliente'))
      ..on('GET', '/users/profile', {
        'id': '33333333-3333-3333-3333-333333333333',
        'nombre': 'Carlos Pérez',
        'email': 'carlos@quickbite.mx',
        'rol': 'cliente',
      })
      ..on('GET', '/products', pagina([producto()]))
      ..on('GET', '/categories', const [])
      ..on('GET', '/notifications', const []);

    await tester.enterText(
      find.byType(TextFormField).first,
      'carlos@quickbite.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await asentar(tester);

    // Entra y, sobre todo, no arrastra el aviso de la expiración anterior.
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('Tu sesión ha expirado'), findsNothing);
  });
}

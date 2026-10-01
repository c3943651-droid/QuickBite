import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../address/presentation/addresses_screens_test.dart';

/// Regresión: los botones de la mitad inferior de `/addresses` deben responder.
///
/// `/addresses` se declara en las rutas **raíz** (fuera del
/// `StatefulShellRoute`), así que se empuja en el navigator raíz por encima del
/// shell. El shell usa `extendBody: true` para que la barra flotante "flote"
/// sobre el contenido; si además esa barra se mantiene visible por encima de la
/// ruta, queda una franja invisible que se queda con los toques de abajo y los
/// botones ("Agregar", el FAB, "Ubicar en el mapa") dejan de responder.
void main() {
  const sesion = AuthSession(
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
    user: AuthUser(id: 'u1', nombre: 'Test', email: 't@t.com', rol: 'cliente'),
  );

  late GoRouter router;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    router = createRouter(() async => sesion);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addressRepositoryProvider.overrideWithValue(FakeAddressRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _asentar(tester);

    router.go('/addresses');
    await _asentar(tester);
  }

  testWidgets('el FAB inferior de /addresses abre el formulario', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Casa'), findsOneWidget);

    await tester.tap(find.text('Agregar dirección').last);
    await _asentar(tester);

    expect(find.byType(TextFormField), findsWidgets);
  });
}

/// Avanza unos pocos fotogramas: hay pantallas con animaciones continuas que
/// impiden que `pumpAndSettle` termine.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../support/catalog_fakes.dart';
import '../../support/fake_token_storage.dart';

/// El Perfil se queda en "cargando" si `fetchProfile` no responde, así que aquí
/// hace falta un perfil de verdad: el resto de métodos no se usan en esta ruta.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> fetchProfile() async => const UserProfile(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
    telefono: '5512345678',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Regresión del Moto G15: la barra de navegación flota (`extendBody: true`),
/// así que el cuerpo de la pantalla queda **debajo** de ella. Una lista que no
/// reserva esa franja acaba con sus últimas filas atrapadas detrás de la barra,
/// sin forma de alcanzarlas. En el Perfil eran "Avanzado" y "Cerrar sesión".
void main() {
  const cliente = AuthSession(
    tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
    user: AuthUser(
      id: '33333333-3333-3333-3333-333333333333',
      nombre: 'Carlos Pérez',
      email: 'carlos@quickbite.mx',
      rol: 'cliente',
    ),
  );

  Future<void> pumpPerfil(WidgetTester tester) async {
    // Geometría real del Moto G15: 1080x2400 físicos a 400 dpi son 432x960
    // lógicos. Con dpr 1 la pantalla "virtual" mide 2400 px lógicos de alto, el
    // contenido sobra y el solapamiento con la barra nunca aparece —el test
    // pasaba sin detectar el bug que se vio en el dispositivo.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    // `FakeViewPadding` va en píxeles FÍSICOS. La barra de 3 botones del Moto
    // mide 48 lógicos = 120 físicos; poner 48 aquí modelaba 19 lógicos y el
    // test volvía a pasar sin reproducir el tapado real.
    tester.view.padding = const FakeViewPadding(top: 128, bottom: 120);
    tester.view.viewPadding = const FakeViewPadding(top: 128, bottom: 120);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => cliente);
    addTearDown(router.dispose);
    router.go('/profile');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> desplazarAlFinal(WidgetTester tester) async {
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -3000),
      4000,
    );
    await tester.pumpAndSettle();
  }

  group('el contenido del Perfil deja libre la barra flotante', () {
    testWidgets('la última fila del menú queda por encima de la barra', (
      tester,
    ) async {
      await pumpPerfil(tester);
      await desplazarAlFinal(tester);

      final barra = tester.getRect(find.byType(NavigationBar));
      final ultimaFila = tester.getRect(find.text('Avanzado'));

      expect(
        ultimaFila.bottom,
        lessThanOrEqualTo(barra.top),
        reason: '"Avanzado" queda tapada detrás de la barra flotante',
      );
    });

    testWidgets('el botón de cerrar sesión queda por encima de la barra', (
      tester,
    ) async {
      await pumpPerfil(tester);
      await desplazarAlFinal(tester);

      final barra = tester.getRect(find.byType(NavigationBar));
      final boton = tester.getRect(find.text('Cerrar sesión'));

      expect(
        boton.bottom,
        lessThanOrEqualTo(barra.top),
        reason: 'la acción principal del Perfil es la que peor se leía',
      );
    });
  });
}

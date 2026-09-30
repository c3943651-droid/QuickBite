import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/haptics.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';

import '../../support/router_harness.dart';

/// Barra de navegación flotante.
///
/// Antes era una `NavigationBar` pegada al borde inferior, con fondo blanco fijo
/// que en modo oscuro dejaba una mancha ilegible. Ahora flota: tarjeta
/// redondeada, superficie translúcida y acento brillante en la pestaña activa.
void main() {
  group('barra de navegación flotante', () {
    testWidgets('flota sobre el fondo con esquinas redondeadas', (
      tester,
    ) async {
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      // El contenedor de la barra es el ancestro más cercano de la
      // `NavigationBar`; buscar "el primer Container" traía las tarjetas del
      // cuerpo de la pantalla.
      final contenedor = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoracion = contenedor.decoration as BoxDecoration;

      expect(decoracion.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(decoracion.color, AppColors.surface);
      expect(decoracion.boxShadow, isNotEmpty);
    });

    testWidgets('la barra vive dentro de un área segura', (tester) async {
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      // Sin esto, el gesto inferior de Android 15 se come la barra.
      final area = tester.widget<SafeArea>(
        find
            .ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(SafeArea),
            )
            .first,
      );
      expect(area.bottom, isTrue);
      expect(area.minimum, isNotNull);
    });

    testWidgets('queda por encima de la barra de navegación del sistema', (
      tester,
    ) async {
      // Regresión del Moto G15: con la barra de 3 botones, si el `SafeArea` no
      // aplica el inset inferior, los botones del sistema se dibujan encima de
      // las etiquetas de la barra y la pantalla parece rota.
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      final barra = tester.getRect(find.byType(NavigationBar));
      final altoPantalla =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      // El margen de `SafeArea` + el `AppSpacing.md` mínimo, con tolerancia
      // para el redondeo del inset.
      expect(barra.bottom, lessThan(altoPantalla - 48 + 1));
    });

    testWidgets('conserva los destinos de cada rol', (tester) async {
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Catálogo'), findsOneWidget);
    });

    testWidgets('el indicador activo usa el acento de marca', (tester) async {
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(barra.indicatorColor, AppColors.accent);
    });

    testWidgets('el fondo se adapta al tema en vez de quedar fijo', (
      tester,
    ) async {
      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
      // Transparente, no blanco fijo: el color lo pone la tarjeta que la
      // envuelve, que sí conoce el tema.
      expect(barra.backgroundColor, Colors.transparent);
    });
  });

  group('cambio de pestaña', () {
    testWidgets('navega a la ruta de la pestaña', (tester) async {
      final router = await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      await tester.tap(find.text('Historial'));
      await settle(tester);

      expect(locationOf(router), '/history');
    });

    testWidgets('devuelve feedback háptico al cambiar de pestaña', (
      tester,
    ) async {
      final mensajes = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            mensajes.add(call);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        AppHaptics.enabled = true;
      });
      AppHaptics.enabled = true;

      await pumpRouter(tester, sessionFor('cliente'));
      await settle(tester);

      await tester.tap(find.text('Historial'));
      await settle(tester);

      expect(mensajes.map((c) => c.method), contains('HapticFeedback.vibrate'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/app_top_bar.dart';

import '../../support/widget_harness.dart';

void main() {
  group('AppTopBar (09 §8.9)', () {
    testWidgets('muestra el título alineado a la izquierda por defecto', (
      tester,
    ) async {
      await pumpApp(tester, const AppTopBar(title: 'Historial'));

      expect(find.text('Historial'), findsOneWidget);
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.centerTitle, isFalse);
      expect(bar.elevation, 0);
    });

    testWidgets('admite título centrado', (tester) async {
      await pumpApp(
        tester,
        const AppTopBar(title: 'Seguimiento', centerTitle: true),
      );

      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    });

    testWidgets('el fondo en reposo es el del tema, sin elevación', (
      tester,
    ) async {
      await pumpApp(tester, const AppTopBar(title: 'Historial'));

      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, AppColors.white);
      expect(bar.elevation, 0);
      expect(bar.scrolledUnderElevation, 2);
    });

    testWidgets('en tema oscuro usa la superficie oscura', (tester) async {
      await pumpApp(
        tester,
        const AppTopBar(title: 'Historial'),
        theme: ThemeData.dark(useMaterial3: true),
      );

      expect(
        tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
        isNot(AppColors.white),
      );
    });

    testWidgets('las acciones se renderizan a la derecha', (tester) async {
      await pumpApp(
        tester,
        AppTopBar(
          title: 'Catálogo',
          actions: [
            NotificationButton(icon: Icons.notifications, onTap: () {}),
          ],
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('el botón de retroceso solo aparece si hay a dónde volver', (
      tester,
    ) async {
      await pumpApp(tester, const AppTopBar(title: 'Detalle'));
      expect(find.byType(BackButton), findsNothing);

      await pumpApp(tester, AppTopBar(title: 'Detalle', onBack: () {}));
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('el retroceso avisa del toque', (tester) async {
      var toques = 0;
      await pumpApp(
        tester,
        AppTopBar(title: 'Detalle', onBack: () => toques++),
      );

      await tester.tap(find.byType(BackButton));
      await tester.pump();

      expect(toques, 1);
    });

    testWidgets('el título largo se limita a dos líneas', (tester) async {
      await pumpApp(
        tester,
        const AppTopBar(title: 'Preferencias de notificaciones push'),
      );

      final title = tester.widget<Text>(
        find.text('Preferencias de notificaciones push'),
      );
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });
}

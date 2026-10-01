import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';

/// Monta un widget con el tema real de la app.
///
/// Los componentes transversales de H0.3 se consumen desde más de 20 pantallas,
/// así que los tests comprueban contra `AppTheme` y no contra un tema de
/// ejemplo: si un componente se salta el tema, la suite lo detecta.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  // Ver `router_harness`: sin inset inferior las `SafeArea` no hacen nada y los
  // tests no reproducen lo que pasa en el dispositivo con 3 botones.
  tester.view.padding = const FakeViewPadding(top: 51, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 51, bottom: 48);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Igual que [pumpApp] pero para probar acciones que necesitan su propio
/// `Navigator` (diálogos, bottom sheets).
Future<void> pumpWithButton(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// `pumpAndSettle` no converge con animaciones continuas (el pulso del paso
/// actual del timeline), así que se avanza un tiempo fijo.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 300));
}

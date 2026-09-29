import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/connectivity/conectividad.dart';
import 'package:quickbite_mobile/src/core/widgets/overlay_conexion.dart';

import '../../support/fake_conectividad.dart';
import '../../support/widget_harness.dart';

void main() {
  group('OverlayConexion (07.1 SCR-COM-01)', () {
    testWidgets('no muestra nada cuando hay conexion', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(FakeConectividad())],
          child: const MaterialApp(
            home: Scaffold(body: OverlayConexion(child: Text('contenido'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('contenido'), findsOneWidget);
      expect(find.text('Sin conexión a internet'), findsNothing);
    });

    testWidgets('muestra el aviso cuando se pierde la conexion', (tester) async {
      final fake = FakeConectividad(conectado: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: Scaffold(body: OverlayConexion(child: Text('contenido'))),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sin conexión a internet'), findsNothing);

      fake.emitir(false);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión a internet'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('el boton Reintentar consulta de nuevo la conexion', (tester) async {
      final fake = FakeConectividad(conectado: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: Scaffold(body: OverlayConexion(child: Text('contenido'))),
          ),
        ),
      );
      await tester.pump();
      final consultasAntes = fake.consultas;

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(fake.consultas, greaterThan(consultasAntes));
    });

    testWidgets('el aviso desaparece al volver la conexion', (tester) async {
      final fake = FakeConectividad(conectado: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: Scaffold(body: OverlayConexion(child: Text('contenido'))),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Sin conexión a internet'), findsOneWidget);

      fake.emitir(true);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión a internet'), findsNothing);
      expect(find.text('contenido'), findsOneWidget);
    });

    testWidgets('muestra una cinta sobre el contenido sin taparlo del todo', (
      tester,
    ) async {
      final fake = FakeConectividad(conectado: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: Scaffold(body: OverlayConexion(child: Text('contenido'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('contenido'), findsOneWidget);
      expect(find.byType(OfflineBanner), findsOneWidget);
    });
  });

  group('cinta sin conexion', () {
    testWidgets('es una cinta compacta, no una pantalla a pantalla completa', (
      tester,
    ) async {
      await pumpApp(tester, const Scaffold(body: OfflineBanner()));

      final cinta = tester.getSize(find.byType(OfflineBanner));

      expect(cinta.height, lessThan(120));
    });
  });

  group('SinConexionView (pantalla completa SCR-COM-01)', () {
    testWidgets('muestra ilustracion, mensaje, descripcion y reintentar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(FakeConectividad())],
          child: const MaterialApp(home: Scaffold(body: SinConexionView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text(AvisoRed.sinConexion), findsOneWidget);
      expect(find.text(AvisoRed.descripcion), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('Reintentar vuelve a consultar el estado de red', (tester) async {
      final fake = FakeConectividad();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: Scaffold(body: SinConexionView())),
        ),
      );
      await tester.pumpAndSettle();
      final consultasAntes = fake.consultas;

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(fake.consultas, greaterThan(consultasAntes));
    });
  });

  group('guardia de acciones de red', () {
    testWidgets('sin conexion, avisa y no ejecuta la accion', (tester) async {
      var ejecutada = false;
      final fake = FakeConectividad(conectado: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => guardiaDeRed(
                    context,
                    ref: ref,
                    accion: () async => ejecutada = true,
                  ),
                  child: const Text('Pagar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Pagar'));
      await tester.pump();

      expect(ejecutada, isFalse);
      expect(find.text(AvisoRed.sinConexion), findsOneWidget);
    });

    testWidgets('con conexion, ejecuta la accion sin avisar', (tester) async {
      var ejecutada = false;
      final fake = FakeConectividad(conectado: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [conectividadProvider.overrideWithValue(fake)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => guardiaDeRed(
                    context,
                    ref: ref,
                    accion: () async => ejecutada = true,
                  ),
                  child: const Text('Pagar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Pagar'));
      await tester.pump();

      expect(ejecutada, isTrue);
      expect(find.text(AvisoRed.sinConexion), findsNothing);
    });
  });
}

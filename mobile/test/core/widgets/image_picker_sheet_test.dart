import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/images/seleccion_imagen.dart';
import 'package:quickbite_mobile/src/core/widgets/image_picker_sheet.dart';

import '../../support/widget_harness.dart';

void main() {
  Future<String?> abrirHoja(
    WidgetTester tester, {
    required SelectorImagen selector,
  }) async {
    String? elegida;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [selectorImagenProvider.overrideWithValue(selector)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  elegida = await mostrarSelectorImagen(context);
                },
                child: const Text('Cambiar'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    return elegida;
  }

  testWidgets('la hoja ofrece camara, galeria y cancelar (07.1 SCR-COM-04)', (
    tester,
  ) async {
    await pumpWithButton(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => mostrarSelectorImagen(context),
          child: const Text('Cambiar'),
        ),
      ),
    );

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();

    expect(find.text('Cámara'), findsOneWidget);
    expect(find.text('Galería'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('elegir camara devuelve la ruta y cierra la hoja', (
    tester,
  ) async {
    final selector = FakeSelectorImagen('/tmp/camara.jpg');

    await abrirHoja(tester, selector: selector);
    await tester.tap(find.text('Cámara'));
    await tester.pumpAndSettle();

    expect(selector.origenes, [OrigenImagen.camara]);
    expect(find.text('Cámara'), findsNothing);
  });

  testWidgets('elegir galeria pide a la galeria', (tester) async {
    final selector = FakeSelectorImagen('/tmp/galeria.jpg');

    await abrirHoja(tester, selector: selector);
    await tester.tap(find.text('Galería'));
    await tester.pumpAndSettle();

    expect(selector.origenes, [OrigenImagen.galeria]);
  });

  testWidgets('cancelar no llama al selector y devuelve null', (tester) async {
    final selector = FakeSelectorImagen('/tmp/camara.jpg');

    final elegida = await abrirHoja(tester, selector: selector);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(selector.origenes, isEmpty);
    expect(elegida, isNull);
  });
}

class FakeSelectorImagen implements SelectorImagen {
  FakeSelectorImagen(this.ruta);

  final String? ruta;
  final List<OrigenImagen> origenes = [];

  @override
  Future<String?> seleccionar(OrigenImagen origen) async {
    origenes.add(origen);
    return ruta;
  }
}

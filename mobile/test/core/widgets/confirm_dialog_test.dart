import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/confirm_dialog.dart';

import '../../support/widget_harness.dart';

void main() {
  group('ConfirmDialog (09 §8.7)', () {
    testWidgets('confirma y devuelve true', (tester) async {
      bool? resultado;
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await ConfirmDialog.show(
                context,
                title: '¿Vaciar el carrito?',
                message: 'Se quitarán todos los productos.',
                confirmLabel: 'Vaciar',
              );
            },
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pump();
      await settle(tester);

      expect(find.text('¿Vaciar el carrito?'), findsOneWidget);
      expect(find.text('Se quitarán todos los productos.'), findsOneWidget);

      await tester.tap(find.text('Vaciar'));
      await settle(tester);

      expect(resultado, isTrue);
    });

    testWidgets('cancela y devuelve false', (tester) async {
      bool? resultado;
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await ConfirmDialog.show(
                context,
                title: '¿Cancelar el pedido?',
                message: 'No podrás recuperarlo.',
                confirmLabel: 'Cancelar pedido',
              );
            },
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Volver'));
      await settle(tester);

      expect(resultado, isFalse);
    });

    testWidgets('la acción destructiva pinta el botón de confirmar en rojo', (
      tester,
    ) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ConfirmDialog.show(
              context,
              title: '¿Eliminar?',
              message: 'Acción permanente.',
              confirmLabel: 'Eliminar',
              destructive: true,
            ),
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      final boton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Eliminar'),
      );
      expect(boton.style?.backgroundColor?.resolve({}), AppColors.errorRed);
    });

    testWidgets('permite personalizar las etiquetas de los botones', (
      tester,
    ) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ConfirmDialog.show(
              context,
              title: 'Salir',
              message: '¿Seguro?',
              confirmLabel: 'Salir de la app',
              cancelLabel: 'Quedarme',
            ),
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      expect(find.text('Salir de la app'), findsOneWidget);
      expect(find.text('Quedarme'), findsOneWidget);
    });

    testWidgets('cerrar el diálogo sin decidir devuelve false', (tester) async {
      bool? resultado;
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await ConfirmDialog.show(
                context,
                title: '¿Vaciar?',
                message: 'Mensaje',
                confirmLabel: 'Vaciar',
              );
            },
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tapAt(const Offset(540, 200));
      await settle(tester);

      expect(resultado, isFalse);
    });
  });
}

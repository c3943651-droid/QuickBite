import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/core/widgets/app_bottom_sheet.dart';

import '../../support/widget_harness.dart';

void main() {
  group('AppBottomSheet (09 §8.7)', () {
    testWidgets('muestra asa, título y contenido', (tester) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppBottomSheet.show<void>(
              context,
              title: 'Filtros',
              child: const Text('Rango de precio'),
            ),
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Rango de precio'), findsOneWidget);
    });

    testWidgets('el asa de arrastre identifica el componente', (tester) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppBottomSheet.show<void>(
              context,
              title: 'Filtros',
              child: const Text('Contenido'),
            ),
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      expect(find.byType(SheetDragHandle), findsOneWidget);
    });

    testWidgets('el título es opcional', (tester) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppBottomSheet.show<void>(
              context,
              child: const Text('Solo contenido'),
            ),
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      expect(find.text('Solo contenido'), findsOneWidget);
    });

    testWidgets('se cierra tocando fuera y devuelve null', (tester) async {
      Object? resultado = 'sin tocar';
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await AppBottomSheet.show<String>(
                context,
                title: 'Elige',
                child: const Text('Contenido'),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tapAt(const Offset(540, 100));
      await settle(tester);

      expect(resultado, isNull);
    });

    testWidgets('una acción puede devolver un valor', (tester) async {
      String? resultado;
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              resultado = await AppBottomSheet.show<String>(
                context,
                title: 'Elige',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('precio'),
                      child: const Text('Precio'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Precio'));
      await settle(tester);

      expect(resultado, 'precio');
    });

    testWidgets('respeta el tema oscuro', (tester) async {
      await pumpWithButton(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppBottomSheet.show<void>(
              context,
              title: 'Filtros',
              child: const Text('Contenido'),
            ),
            child: const Text('abrir'),
          ),
        ),
        theme: AppTheme.dark,
      );

      await tester.tap(find.text('abrir'));
      await settle(tester);

      final surface = tester
          .widgetList<Material>(find.byType(Material))
          .where(
            (m) =>
                m.color != null && m.color == AppTheme.dark.colorScheme.surface,
          )
          .toList();
      expect(surface, isNotEmpty);
    });
  });
}

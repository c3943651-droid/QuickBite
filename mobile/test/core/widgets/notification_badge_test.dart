import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/notification_badge.dart';

import '../../support/widget_harness.dart';

void main() {
  group('NotificationBadge (09 §8.4)', () {
    testWidgets('no muestra nada cuando no hay notificaciones', (tester) async {
      await pumpApp(
        tester,
        const NotificationBadge(count: 0, child: Icon(Icons.notifications)),
      );

      expect(find.byType(Badge), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('muestra el número sin leídas', (tester) async {
      await pumpApp(
        tester,
        const NotificationBadge(count: 3, child: Icon(Icons.notifications)),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('el contador se acota a 99+', (tester) async {
      await pumpApp(
        tester,
        const NotificationBadge(count: 120, child: Icon(Icons.notifications)),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('el círculo es rojo con el número en blanco (09 §8.4)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const NotificationBadge(count: 5, child: Icon(Icons.notifications)),
      );

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.backgroundColor, AppColors.accentAlt);
      expect(badge.textColor, AppColors.white);
    });

    testWidgets('admite un color de marca propio', (tester) async {
      await pumpApp(
        tester,
        const NotificationBadge(
          count: 2,
          color: AppColors.info,
          child: Icon(Icons.notifications),
        ),
      );

      expect(
        tester.widget<Badge>(find.byType(Badge)).backgroundColor,
        AppColors.info,
      );
    });

    testWidgets('un contador negativo se trata como cero', (tester) async {
      await pumpApp(
        tester,
        const NotificationBadge(count: -1, child: Icon(Icons.notifications)),
      );

      expect(find.byType(Badge), findsNothing);
    });
  });
}

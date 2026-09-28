import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_confirmation_screen.dart';

const _pedido = Order(
  id: 'o1',
  numeroPedido: 'QB-20260927-AB12CD',
  estado: 'Pendiente',
  total: 171,
  direccionEntrega: 'Av. Reforma 222, Int 3, Casa, CDMX',
  items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
);

void main() {
  Future<void> pumpConfirmation(
    WidgetTester tester, {
    Order? pedido = _pedido,
  }) async {
    final container = ProviderContainer(
      overrides: [
        if (pedido != null) lastOrderProvider.overrideWithValue(pedido),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/order/confirmation/${pedido?.id ?? 'o1'}',
      routes: [
        GoRoute(
          path: '/order/confirmation/:id',
          builder: (_, state) =>
              OrderConfirmationScreen(orderId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/order/:id',
          builder: (_, _) => const Scaffold(body: Text('Seguimiento real')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Catálogo real')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OrderConfirmationScreen (07.1 SCR-CART-03)', () {
    testWidgets('confirma el pedido con su número', (tester) async {
      await pumpConfirmation(tester);

      expect(find.text('¡Pedido confirmado!'), findsOneWidget);
      expect(find.text('QB-20260927-AB12CD'), findsOneWidget);
    });

    testWidgets('muestra el resumen con items, total y dirección', (
      tester,
    ) async {
      await pumpConfirmation(tester);

      expect(find.text('2 × Tacos al pastor'), findsOneWidget);
      expect(find.text(r'$171.00'), findsWidgets);
      expect(find.textContaining('Av. Reforma 222'), findsWidgets);
    });

    testWidgets('muestra el tiempo estimado de entrega', (tester) async {
      await pumpConfirmation(tester);

      expect(find.textContaining('40 min'), findsWidgets);
    });

    testWidgets('el botón principal lleva al seguimiento del pedido', (
      tester,
    ) async {
      await pumpConfirmation(tester);

      await tester.tap(find.text('Seguir pedido'));
      await tester.pumpAndSettle();

      expect(find.text('Seguimiento real'), findsOneWidget);
    });

    testWidgets('el botón secundario vuelve al catálogo', (tester) async {
      await pumpConfirmation(tester);

      await tester.tap(find.text('Volver al catálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Catálogo real'), findsOneWidget);
    });

    testWidgets('sin pedido en memoria ofrece volver al catálogo', (
      tester,
    ) async {
      await pumpConfirmation(tester, pedido: null);

      expect(find.text('¡Pedido confirmado!'), findsNothing);
      expect(find.text('Volver al catálogo'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';

import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_screen.dart';

import '../../../support/cart_fakes.dart';

CartItem _item({
  String id = 'i1',
  String nombre = 'Tacos al pastor',
  double precio = 85.50,
  int cantidad = 2,
  List<String> opciones = const ['Extra queso'],
  String? observaciones,
}) {
  return CartItem(
    id: id,
    productoId: 'p1',
    nombre: nombre,
    precio: precio,
    cantidad: cantidad,
    opciones: opciones,
    observaciones: observaciones,
  );
}

void main() {
  late FakeCartRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCartRepository();
    container = ProviderContainer(
      overrides: [cartRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpCart(
    WidgetTester tester, {
    Cart? cart,
    String initialLocation = '/cart',
  }) async {
    if (cart != null) {
      repository.current = cart;
    }
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const Scaffold(body: Text('Checkout real')),
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

  group('CartScreen (07.1 SCR-CART-01)', () {
    testWidgets('lista los items con precio, opciones y subtotal', (
      tester,
    ) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(find.text('Extra queso'), findsOneWidget);
      expect(find.text(r'$171.00'), findsWidgets);
    });

    testWidgets('el resumen muestra subtotal, envío y total', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(
          id: 'cart-1',
          items: [_item()],
          total: 216,
          costoEnvioApi: 45,
        ),
      );

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Costo de envío'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(r'$171.00'), findsWidgets);
      expect(find.text(r'$45.00'), findsOneWidget);
      expect(find.text(r'$216.00'), findsWidgets);
    });

    testWidgets('sin envío configurado la línea muestra cero', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('el selector de cantidad sube y baja', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      expect(repository.updates.single.cantidad, 3);

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pumpAndSettle();
      expect(repository.updates.last.cantidad, 2);
    });

    testWidgets('el botón de eliminar quita el item', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      await tester.tap(find.byTooltip('Eliminar del carrito'));
      await tester.pumpAndSettle();

      expect(repository.removed, ['i1']);
    });

    testWidgets('"Vaciar carrito" pide confirmación antes de vaciar', (
      tester,
    ) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Vaciar carrito'));
      await tester.pumpAndSettle();
      expect(find.text('¿Vaciar el carrito?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Volver'));
      await tester.pumpAndSettle();
      expect(repository.clearCalls, 0);
      expect(find.text('Tacos al pastor'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Vaciar carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sí, vaciar'));
      await tester.pumpAndSettle();

      expect(repository.clearCalls, 1);
    });

    testWidgets('"Proceder al pago" navega al checkout', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );

      await tester.tap(find.text('Proceder al pago'));
      await tester.pumpAndSettle();

      expect(find.text('Checkout real'), findsOneWidget);
    });

    testWidgets('el carrito vacío ofrece explorar el menú', (tester) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: const [], total: 0),
      );

      expect(find.text('Tu carrito está vacío'), findsOneWidget);

      await tester.tap(find.text('Explorar menú'));
      await tester.pumpAndSettle();

      expect(find.text('Catálogo real'), findsOneWidget);
    });

    testWidgets('un error de red muestra reintentar', (tester) async {
      repository.error = const NetworkException();
      await pumpCart(tester);

      expect(find.text('Reintentar'), findsOneWidget);

      repository.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
    });

    testWidgets('muestra el estado de carga antes de los items', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('un fallo al vaciar avisa sin perder los items', (
      tester,
    ) async {
      await pumpCart(
        tester,
        cart: Cart(id: 'cart-1', items: [_item()], total: 171),
      );
      repository.clearError = const ServerException();

      await tester.tap(find.widgetWithText(TextButton, 'Vaciar carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sí, vaciar'));
      await tester.pumpAndSettle();

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(
        find.text('Ocurrió un error inesperado. Inténtalo de nuevo más tarde.'),
        findsOneWidget,
      );
    });
  });
}

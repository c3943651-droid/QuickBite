import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_entities.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_screen.dart';

import '../../../support/cart_fakes.dart';
import '../../../support/order_fakes.dart';

const _direcciones = [
  Address(
    id: 'a1',
    calle: 'Av. Reforma 222',
    numero: 'Int 3',
    ciudad: 'CDMX',
    alias: 'Casa',
    esPredeterminada: true,
  ),
  Address(
    id: 'a2',
    calle: 'Av. Insurgentes 100',
    ciudad: 'CDMX',
    alias: 'Oficina',
  ),
];

void main() {
  late FakeCartRepository cartRepository;
  late FakeOrderRepository orderRepository;
  late ProviderContainer container;

  setUp(() {
    cartRepository = FakeCartRepository();
    orderRepository = FakeOrderRepository(cart: cartRepository);
  });

  Future<void> pumpCheckout(
    WidgetTester tester, {
    Cart? cart,
    List<Address> direcciones = _direcciones,
  }) async {
    if (cart != null) cartRepository.current = cart;
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepository),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        addressesProvider.overrideWith((ref) async => direcciones),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(
          path: '/order/confirmation/:id',
          builder: (_, state) => Scaffold(
            body: Text('Confirmación real ${state.pathParameters['id']}'),
          ),
        ),
        GoRoute(
          path: '/addresses/new',
          builder: (_, _) => const Scaffold(body: Text('Nueva dirección')),
        ),
        GoRoute(
          path: '/cart',
          builder: (_, _) => const Scaffold(body: Text('Carrito real')),
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

  Cart carritoLleno() => const Cart(
    id: 'cart-1',
    items: [
      CartItem(
        id: 'i1',
        productoId: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        cantidad: 2,
      ),
    ],
    total: 171,
  );

  group('CheckoutScreen (07.1 SCR-CART-02)', () {
    testWidgets('preselecciona la dirección predeterminada', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno());

      expect(find.text('Av. Reforma 222 Int 3, CDMX'), findsOneWidget);
      expect(container.read(checkoutDireccionProvider)?.id, 'a1');
    });

    testWidgets('la AppBar lleva título y botón de regreso al carrito', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno());

      expect(find.text('Confirmar pedido'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Carrito real'), findsOneWidget);
    });

    testWidgets('permite elegir otra dirección de la lista', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.tap(find.text('Av. Insurgentes 100, CDMX'));
      await tester.pumpAndSettle();

      expect(container.read(checkoutDireccionProvider)?.id, 'a2');
    });

    testWidgets('sin direcciones solo ofrece agregar una nueva', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno(), direcciones: const []);

      expect(find.text('Agregar nueva dirección'), findsOneWidget);
      expect(find.text('Confirmar pedido'), findsOneWidget);
      expect(container.read(checkoutDireccionProvider), isNull);
    });

    testWidgets('navega a agregar dirección', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno(), direcciones: const []);

      await tester.tap(find.text('Agregar nueva dirección'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva dirección'), findsOneWidget);
    });

    testWidgets('ofrece los dos métodos de pago simulados', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno());

      expect(find.text('Efectivo contra entrega'), findsOneWidget);
      expect(find.text('Tarjeta (simulado)'), findsOneWidget);
      expect(container.read(checkoutProvider).metodoPago, MetodoPago.efectivo);
    });

    testWidgets('el método de pago seleccionado queda en el estado', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.tap(find.text('Tarjeta (simulado)'));
      await tester.pumpAndSettle();

      expect(container.read(checkoutProvider).metodoPago, MetodoPago.tarjeta);
    });

    testWidgets('el resumen muestra items, subtotal, envío y total', (
      tester,
    ) async {
      await pumpCheckout(
        tester,
        cart: Cart(
          id: 'cart-1',
          items: carritoLleno().items,
          total: 216,
          costoEnvioApi: 45,
        ),
      );

      expect(find.text('2 × Tacos al pastor'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Costo de envío'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(r'$216.00'), findsWidgets);
    });

    testWidgets('el botón principal lleva el total a confirmar', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno());

      expect(find.text(r'Confirmar pedido - $171.00'), findsOneWidget);
    });

    testWidgets('las notas de entrega se guardan en el estado', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        'Tocar el timbre',
      );
      await tester.pumpAndSettle();

      expect(container.read(checkoutProvider).notas, 'Tocar el timbre');
    });

    testWidgets('confirma el pedido y navega a la confirmación', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.tap(find.text(r'Confirmar pedido - $171.00'));
      await tester.pumpAndSettle();

      expect(orderRepository.creados, hasLength(1));
      expect(find.text('Confirmación real o1'), findsOneWidget);
    });

    testWidgets('el carrito queda vacío tras confirmar', (tester) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.tap(find.text(r'Confirmar pedido - $171.00'));
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).requireValue.isEmpty, isTrue);
    });

    testWidgets('con carrito vacío no permite confirmar', (tester) async {
      await pumpCheckout(
        tester,
        cart: const Cart(id: 'cart-1', items: [], total: 0),
      );

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, r'Confirmar pedido - $0.00'),
        findsNothing,
      );
    });

    testWidgets(
      'muestra el error de stock insuficiente sin limpiar el carrito',
      (tester) async {
        orderRepository.error = const ValidationException(
          'Stock insuficiente: Tacos al pastor',
        );
        await pumpCheckout(tester, cart: carritoLleno());

        await tester.tap(find.text(r'Confirmar pedido - $171.00'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Stock insuficiente'), findsWidgets);
        expect(find.text('Confirmación real o1'), findsNothing);
        expect(container.read(cartProvider).requireValue.isEmpty, isFalse);
      },
    );

    testWidgets('el botón se bloquea mientras valida el pedido', (
      tester,
    ) async {
      await pumpCheckout(tester, cart: carritoLleno());

      await tester.tap(find.text(r'Confirmar pedido - $171.00'));
      await tester.pump();

      expect(
        find.widgetWithText(FilledButton, r'Confirmar pedido - $171.00'),
        findsNothing,
      );

      await tester.pumpAndSettle();
      expect(find.text('Confirmación real o1'), findsOneWidget);
    });
  });
}

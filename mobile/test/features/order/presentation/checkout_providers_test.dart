import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/address/domain/address_entities.dart';
import 'package:quickbite_mobile/src/features/address/presentation/address_providers.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';

import '../../../support/cart_fakes.dart';
import '../../../support/order_fakes.dart';

const _sucursal = Address(
  id: 'a1',
  calle: 'Av. Reforma 222',
  numero: 'Int 3',
  ciudad: 'CDMX',
  alias: 'Casa',
  esPredeterminada: true,
);

const _oficina = Address(
  id: 'a2',
  calle: 'Av. Insurgentes 100',
  ciudad: 'CDMX',
  alias: 'Oficina',
);

void main() {
  late FakeCartRepository cartRepository;
  late FakeOrderRepository orderRepository;
  late ProviderContainer container;

  setUp(() {
    cartRepository = FakeCartRepository();
    orderRepository = FakeOrderRepository(cart: cartRepository);
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepository),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        addressesProvider.overrideWith((ref) async => [_sucursal, _oficina]),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> cargar() async {
    container.listen(cartProvider, (_, _) {});
    await container.read(cartProvider.future);
    await container.read(addressesProvider.future);
  }

  void carritoConItems() {
    cartRepository.current = const Cart(
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
  }

  group('dirección efectiva', () {
    test('preselecciona la dirección predeterminada', () async {
      await container.read(addressesProvider.future);

      expect(container.read(checkoutDireccionProvider)?.id, 'a1');
    });

    test('el usuario puede cambiar a otra dirección', () async {
      await container.read(addressesProvider.future);

      container.read(checkoutProvider.notifier).seleccionarDireccion('a2');

      expect(container.read(checkoutDireccionProvider)?.id, 'a2');
    });

    test('sin direcciones guardadas no hay ninguna efectiva', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cartRepository),
          orderRepositoryProvider.overrideWithValue(orderRepository),
          addressesProvider.overrideWith((ref) async => const []),
        ],
      );
      await container.read(addressesProvider.future);

      expect(container.read(checkoutDireccionProvider), isNull);
    });
  });

  group('confirmar', () {
    test('no crea el pedido con el carrito vacío', () async {
      await cargar();

      final resultado = await container.read(checkoutProvider.notifier).confirmar();

      expect(resultado, isNull);
      expect(container.read(checkoutProvider).error, contains('vacío'));
      expect(orderRepository.creados, isEmpty);
    });

    test('exige una dirección de entrega', () async {
      carritoConItems();
      await cargar();
      container.dispose();
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(cartRepository),
          orderRepositoryProvider.overrideWithValue(orderRepository),
          addressesProvider.overrideWith((ref) async => const []),
        ],
      );
      await container.read(cartProvider.future);
      await container.read(addressesProvider.future);

      final resultado = await container.read(checkoutProvider.notifier).confirmar();

      expect(resultado, isNull);
      expect(container.read(checkoutProvider).error, contains('dirección'));
      expect(orderRepository.creados, isEmpty);
    });

    test('crea el pedido con dirección, pago y notas', () async {
      carritoConItems();
      await cargar();
      final notifier = container.read(checkoutProvider.notifier)
        ..seleccionarMetodoPago(MetodoPago.tarjeta)
        ..setNotas('Tocar el timbre');

      final resultado = await notifier.confirmar();

      expect(resultado, isNotNull);
      expect(resultado!.numeroPedido, 'QB-20260927-AB12CD');
      final creado = orderRepository.creados.single;
      expect(creado.direccionId, 'a1');
      expect(creado.metodoPago, MetodoPago.tarjeta);
      expect(creado.direccionSnapshot, contains('Av. Reforma 222'));
      expect(creado.direccionSnapshot, contains('Casa'));
      expect(creado.notasEntrega, 'Tocar el timbre');
    });

    test('vacía el carrito tras confirmar', () async {
      carritoConItems();
      await cargar();

      await container.read(checkoutProvider.notifier).confirmar();

      expect(container.read(cartProvider).requireValue.isEmpty, isTrue);
    });

    test('publica el pedido creado para la pantalla de confirmación', () async {
      carritoConItems();
      await cargar();

      await container.read(checkoutProvider.notifier).confirmar();

      expect(
        container.read(lastOrderProvider)?.numeroPedido,
        'QB-20260927-AB12CD',
      );
    });

    test('el error de stock insuficiente no vacía el carrito', () async {
      carritoConItems();
      await cargar();
      orderRepository.error = const ValidationException(
        'Stock insuficiente: Tacos al pastor',
      );

      final resultado = await container.read(checkoutProvider.notifier).confirmar();

      expect(resultado, isNull);
      expect(
        container.read(checkoutProvider).error,
        contains('Stock insuficiente'),
      );
      expect(container.read(cartProvider).requireValue.isEmpty, isFalse);
      expect(container.read(checkoutProvider).enviando, isFalse);
    });

    test('mientras envía no permite un segundo envío', () async {
      carritoConItems();
      await cargar();
      final notifier = container.read(checkoutProvider.notifier);

      final primero = notifier.confirmar();
      final segundo = await notifier.confirmar();
      await primero;

      expect(segundo, isNull);
      expect(orderRepository.creados, hasLength(1));
    });
  });
}

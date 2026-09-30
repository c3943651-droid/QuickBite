import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';

import '../../../support/cart_fakes.dart';

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

  Cart cart() => container.read(cartProvider).requireValue;

  group('cartProvider', () {
    test('carga el carrito al construirse', () async {
      repository.current = Cart(
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

      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      expect(cart().items, hasLength(1));
      expect(cart().total, 171);
    });

    test('cambiar las opciones quita el item y lo vuelve a agregar', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);
      final item = CartItem(
        id: 'i1',
        productoId: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        cantidad: 2,
        opciones: ['Extra queso'],
      );
      repository.current = Cart(id: 'cart-1', items: [item], total: 171);
      await container.read(cartProvider.notifier).refresh();

      await container
          .read(cartProvider.notifier)
          .replaceItemOptions(item, opcionIds: ['o2']);

      expect(repository.removed, ['i1']);
      expect(repository.adds.single.ids, ['o2']);
      expect(repository.adds.single.cantidad, 2);
      expect(cart().items.single.opciones, ['o2']);
    });

    test(
      'cambiar opciones conserva la cantidad y las notas del item',
      () async {
        container.listen(cartProvider, (_, _) {});
        await container.read(cartProvider.future);
        final item = CartItem(
          id: 'i1',
          productoId: 'p1',
          nombre: 'Tacos al pastor',
          precio: 85.50,
          cantidad: 3,
          observaciones: 'Sin cebolla',
        );
        repository.current = Cart(id: 'cart-1', items: [item], total: 256.50);
        await container.read(cartProvider.notifier).refresh();

        await container
            .read(cartProvider.notifier)
            .replaceItemOptions(item, opcionIds: ['o1', 'o3']);

        expect(repository.adds.single.cantidad, 3);
        expect(repository.adds.single.observaciones, 'Sin cebolla');
      },
    );

    test('si el re-agrego falla, el carrito refleja el servidor y avisa', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);
      final item = CartItem(
        id: 'i1',
        productoId: 'p1',
        nombre: 'Tacos al pastor',
        precio: 85.50,
        cantidad: 2,
      );
      repository.current = Cart(id: 'cart-1', items: [item], total: 171);
      await container.read(cartProvider.notifier).refresh();
      repository.failOnAdd = true;

      await expectLater(
        container
            .read(cartProvider.notifier)
            .replaceItemOptions(item, opcionIds: ['o2']),
        throwsA(isA<ValidationException>()),
      );

      // El item ya se había eliminado: el estado se relee del servidor para no
      // mostrar algo que el backend ya no tiene.
      expect(repository.getCalls, greaterThanOrEqualTo(2));
      expect(cart().isEmpty, isTrue);
    });

    test('un carrito vacío no es error', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      expect(cart().isEmpty, isTrue);
    });

    test('agregar un producto deja el carrito con el item', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container
          .read(cartProvider.notifier)
          .addItem(
            productoId: 'p1',
            cantidad: 2,
            observaciones: 'Sin cebolla',
            opcionIds: const ['o1'],
          );

      expect(repository.adds.single.productoId, 'p1');
      expect(repository.adds.single.cantidad, 2);
      expect(repository.adds.single.observaciones, 'Sin cebolla');
      expect(repository.adds.single.ids, ['o1']);
      expect(cart().items, hasLength(1));
      expect(cart().total, 171);
    });

    test('subir la cantidad llama a updateItem y refresca el total', () async {
      repository.current = Cart(
        id: 'cart-1',
        items: [
          CartItem(
            id: 'i1',
            productoId: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            cantidad: 1,
          ),
        ],
        total: 85.50,
      );
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).setQuantity('i1', 3);

      expect(repository.updates.single, (
        itemId: 'i1',
        cantidad: 3,
        observaciones: null,
      ));
      expect(cart().items.single.cantidad, 3);
    });

    test('bajar a 0 elimina el item en vez de mandarlo al backend', () async {
      repository.current = Cart(
        id: 'cart-1',
        items: [
          CartItem(
            id: 'i1',
            productoId: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            cantidad: 1,
          ),
        ],
        total: 85.50,
      );
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).setQuantity('i1', 0);

      expect(repository.updates, isEmpty);
      expect(repository.removed, ['i1']);
      expect(cart().isEmpty, isTrue);
    });

    test('bajar por debajo de 1 se queda en 1', () async {
      repository.current = Cart(
        id: 'cart-1',
        items: [
          CartItem(
            id: 'i1',
            productoId: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            cantidad: 1,
          ),
        ],
        total: 85.50,
      );
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).setQuantity('i1', -3);

      expect(repository.updates, isEmpty);
      expect(cart().items.single.cantidad, 1);
    });

    test('eliminar un item lo quita del estado', () async {
      repository.current = Cart(
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
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).removeItem('i1');

      expect(repository.removed, ['i1']);
      expect(cart().isEmpty, isTrue);
    });

    test('vaciar el carrito llama a clear y deja el carrito vacío', () async {
      repository.current = Cart(
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
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).clear();

      expect(repository.clearCalls, 1);
      expect(cart().isEmpty, isTrue);
    });

    test('vaciar un carrito ya vacío no llama al backend', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      await container.read(cartProvider.notifier).clear();

      expect(repository.clearCalls, 0);
    });

    test(
      'refrescar vuelve a pedir el carrito (el servidor es la fuente)',
      () async {
        container.listen(cartProvider, (_, _) {});
        await container.read(cartProvider.future);
        final antes = repository.getCalls;

        await container.read(cartProvider.notifier).refresh();

        expect(repository.getCalls, antes + 1);
      },
    );

    test('un fallo al agregar conserva el carrito y expone el error', () async {
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);
      repository.failOnAdd = true;

      await expectLater(
        container
            .read(cartProvider.notifier)
            .addItem(productoId: 'p1', cantidad: 9),
        throwsA(isA<ValidationException>()),
      );

      expect(container.read(cartProvider).hasError, isFalse);
      expect(cart().isEmpty, isTrue);
    });

    test('cartItemCountProvider resume el número de items', () async {
      repository.current = Cart(
        id: 'cart-1',
        items: const [
          CartItem(
            id: 'i1',
            productoId: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            cantidad: 2,
          ),
          CartItem(
            id: 'i2',
            productoId: 'p2',
            nombre: 'Agua de horchata',
            precio: 35,
            cantidad: 1,
          ),
        ],
        total: 206,
      );
      container.listen(cartProvider, (_, _) {});
      await container.read(cartProvider.future);

      expect(container.read(cartItemCountProvider), 2);
    });
  });
}

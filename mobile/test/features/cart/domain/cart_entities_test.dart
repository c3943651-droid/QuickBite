import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/cart/domain/cart_entities.dart';

void main() {
  const productoId = 'p1';
  const itemId = 'i1';

  CartItem item({
    String id = itemId,
    String productoId = productoId,
    String nombre = 'Tacos al pastor',
    double precio = 85.50,
    int cantidad = 2,
    List<String> opciones = const [],
    String? observaciones,
    String? imagenUrl,
    double? subtotalApi,
  }) {
    return CartItem(
      id: id,
      productoId: productoId,
      nombre: nombre,
      precio: precio,
      cantidad: cantidad,
      opciones: opciones,
      observaciones: observaciones,
      imagenUrl: imagenUrl,
      subtotalApi: subtotalApi,
    );
  }

  group('CartItem', () {
    test('el subtotal explícito manda sobre precio x cantidad', () {
      expect(item(subtotalApi: 150).subtotal, 150);
    });

    test('sin subtotal explícito se calcula precio x cantidad', () {
      expect(item(precio: 85.50, cantidad: 3).subtotal, 256.50);
    });

    test('un item de cantidad 1 tiene el precio unitario como subtotal', () {
      expect(item(cantidad: 1).subtotal, 85.50);
    });
  });

  group('Cart', () {
    test('sin subtotal de carrito, suma los subtotales de los items', () {
      final cart = Cart(
        id: 'c1',
        items: [
          item(),
          item(id: 'i2', precio: 35, cantidad: 1),
        ],
        total: 0,
      );

      expect(cart.subtotal, 206.00);
    });

    test('el envío explícito se respeta', () {
      final cart = Cart(
        id: 'c1',
        items: [item()],
        costoEnvioApi: 45,
        total: 216,
      );

      expect(cart.costoEnvio, 45);
      expect(cart.total, 216);
    });

    test(
      'si la API no manda envío, se deriva de la diferencia con el total',
      () {
        final cart = Cart(id: 'c1', items: [item()], total: 216);

        expect(cart.subtotal, 171);
        expect(cart.costoEnvio, 45);
      },
    );

    test('un total menor que el subtotal no produce un envío negativo', () {
      final cart = Cart(id: 'c1', items: [item()], total: 100);

      expect(cart.costoEnvio, 0);
    });

    test('isEmpty distingue carrito sin items', () {
      expect(const Cart(id: 'c1', items: [], total: 0).isEmpty, isTrue);
      expect(Cart(id: 'c1', items: [item()], total: 1).isEmpty, isFalse);
    });

    test('cantidad de items para la insignia del carrito', () {
      final cart = Cart(
        id: 'c1',
        items: [
          item(),
          item(id: 'i2'),
        ],
        total: 1,
      );

      expect(cart.cantidadItems, 2);
      expect(const Cart(id: 'c1', items: [], total: 0).cantidadItems, 0);
    });

    test('busca un item por id', () {
      final cart = Cart(
        id: 'c1',
        items: [
          item(),
          item(id: 'i2'),
        ],
        total: 1,
      );

      expect(cart.itemById('i2')?.id, 'i2');
      expect(cart.itemById('nope'), isNull);
    });
  });
}

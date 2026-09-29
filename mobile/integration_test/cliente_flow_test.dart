import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/app_harness.dart';

/// Flujo del cliente de punta a punta (07.3 H8.2):
/// registro/login → catálogo → producto → carrito → checkout → seguimiento.
///
/// La app que se monta es la real; lo único falso es el transporte, así que
/// este archivo detecta lo que los tests por pantalla no ven: que el token
/// llegue al cliente HTTP, que el guard deje pasar al catálogo, que el carrito
/// se componga entre pantallas y que el guard de rol no se coma la navegación.
void main() {
  /// Backend mínimo: sesión de cliente, un producto, carrito que responde y un
  /// pedido que se crea.
  void registrarBackendCliente(AppHarness app) {
    app.http
      ..on('POST', '/auth/login', loginDe('cliente'))
      ..on('GET', '/categories', [
        {
          'id': 'c1',
          'nombre': 'Tacos',
          'descripcion': null,
          'orden': 1,
          'activo': true,
          'icon': null,
        },
      ])
      ..on('GET', '/products', pagina([producto()]))
      ..on('GET', '/products/p1', {
        ...producto(),
        'items': ['Tacos al pastor'],
      })
      ..on('GET', '/products/p1/options', const [])
      ..on('GET', '/users/addresses', [
        {
          'id': 'a1',
          'calle': 'Av. Insurgentes 123',
          'ciudad': 'Ciudad de México',
          'alias': 'Casa',
          'numero': '45',
          'referencia': 'Portón azul',
          'esPredeterminada': true,
        },
      ])
      ..on('GET', '/cart', {'id': 'cart-1', 'items': const [], 'total': 0.0})
      ..on('POST', '/cart/items', {
        'id': 'cart-1',
        'total': 150.0,
        'items': [
          {
            'id': 'ci-1',
            'productoId': 'p1',
            'nombre': 'Tacos al pastor',
            'precio': 150.0,
            'cantidad': 1,
            'opciones': [],
            'subtotal': 150.0,
            'observaciones': null,
            'imagenUrl': null,
          },
        ],
      })
      ..on('POST', '/orders', {
        'id': 'o1',
        'numeroPedido': 'QB-20260928-AA11BB',
        'estado': 'Pendiente',
        'total': 150.0,
        'creadoEn': '2026-09-28T15:00:00Z',
      })
      ..on('GET', '/orders/o1', {
        'id': 'o1',
        'numeroPedido': 'QB-20260928-AA11BB',
        'estado': 'Pendiente',
        'subtotal': 150.0,
        'costoEnvio': 0.0,
        'total': 150.0,
        'items': ['Tacos al pastor'],
      })
      ..on('GET', '/orders/o1/status', {
        'id': 'o1',
        'estado': 'Pendiente',
        'actualizadoEn': '2026-09-28T15:00:00Z',
      })
      ..on(
        'GET',
        '/orders',
        pagina([
          {
            'id': 'o1',
            'numeroPedido': 'QB-20260928-AA11BB',
            'estado': 'Pendiente',
            'total': 150.0,
            'creadoEn': '2026-09-28T15:00:00Z',
          },
        ]),
      );
  }

  testWidgets('el cliente entra, agrega al carrito y llega a su pedido', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);
    registrarBackendCliente(app);

    // 1. Login: la app arranca en el splash y cae a /login.
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'carlos@quickbite.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await asentar(tester);

    // El login golpea la API y el guard lleva al catálogo, no a la pantalla de
    // inicio del repartidor.
    expect(app.http.callsTo('POST', '/auth/login'), 1);
    expect(find.text('Tacos al pastor'), findsOneWidget);

    // 2. Detalle del producto: se piden producto y opciones por separado.
    await tester.tap(find.text('Tacos al pastor'));
    await asentar(tester);
    expect(app.http.callsTo('GET', '/products/p1'), 1);
    expect(find.text('Agregar al carrito - \$150.00'), findsOneWidget);

    // 3. Agregar al carrito: la respuesta del backend repinta el botón.
    await tester.tap(find.text('Agregar al carrito - \$150.00'));
    await asentar(tester);
    expect(app.http.callsTo('POST', '/cart/items'), 1);
    expect(find.text('Agregado al carrito'), findsOneWidget);
    // El snackbar flota sobre la parte baja de la pantalla: si sigue visible,
    // se comería el toque del botón de pago.
    await tester.pump(const Duration(seconds: 5));

    // 4. Carrito: el detalle se abrió a pantalla completa, así que primero se
    // vuelve al shell y se entra por la pestaña inferior.
    await tester.tap(find.byTooltip('Volver'));
    await asentar(tester);
    await tester.tap(find.text('Carrito'));
    await asentar(tester);
    expect(find.text('Tacos al pastor'), findsOneWidget);
    expect(find.text('\$150.00'), findsWidgets);

    // 5. Checkout: confirma el pedido.
    await tester.tap(find.text('Proceder al pago'));
    await asentar(tester);
    expect(find.text('Confirmar pedido'), findsWidgets);

    // El checkout exige una dirección: se elige la que el backend marcó como
    // predeterminada y luego se confirma.
    await tester.tap(find.textContaining('Av. Insurgentes 123'));
    await asentar(tester);
    await tester.tap(find.textContaining('Confirmar pedido -'));
    await asentar(tester);
    expect(app.http.callsTo('POST', '/orders'), 1);

    // 6. Confirmación y seguimiento del pedido.
    expect(find.textContaining('QB-20260928-AA11BB'), findsWidgets);
  });

  testWidgets('un repartidor no puede abrir las rutas de cliente', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);
    app.http
      ..on('POST', '/auth/login', loginDe('repartidor'))
      ..on('GET', '/delivery/available', const [])
      ..on('GET', '/delivery/active', const [])
      ..on('GET', '/delivery/history', const [])
      ..on('GET', '/delivery/stats', {
        'deliveryPersonId': '44444444-4444-4444-4444-444444444444',
        'entregasTotales': 0,
        'entregasDelMes': 0,
        'tiempoPromedioEntregaMinutos': 0,
        'pedidosAsignadosActivos': 0,
        'cancelaciones': 0,
      });

    await tester.enterText(
      find.byType(TextFormField).first,
      'luis@quickbite.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await asentar(tester);

    // El rol manda: entra al shell de repartidor, no al catálogo.
    expect(find.widgetWithText(AppBar, 'Pedidos disponibles'), findsOneWidget);
    expect(find.text('Catálogo'), findsNothing);
    expect(app.http.callsTo('GET', '/delivery/available'), greaterThan(0));
  });
}

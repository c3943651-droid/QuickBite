import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/fake_http.dart';
import '../test/support/app_harness.dart';

/// Flujo del repartidor de punta a punta (07.3 H8.2, H7):
/// login → pedidos disponibles → aceptar → entrega activa → completar.
///
/// Al igual que el flujo del cliente, monta la app real y solo falsea el
/// transporte. Es la prueba que demuestra que el repartidor y el backend
/// comparten contrato: si `POST /delivery/{id}/accept` cambiara, o el guard
/// dejara de separar el shell por rol, este archivo se cae.
void main() {
  /// Backend de reparto con un pedido listo y la transición a en camino.
  void registrarBackendRepartidor(
    AppHarness app, {
    List<Map<String, Object?>> disponibles = const [],
    List<Map<String, Object?>> activos = const [],
  }) {
    app.http
      ..on('POST', '/auth/login', loginDe('repartidor'))
      ..on('GET', '/delivery/available', disponibles)
      ..on('GET', '/delivery/active', activos)
      ..on('GET', '/delivery/history', activos)
      ..on('GET', '/delivery/stats', {
        'deliveryPersonId': '44444444-4444-4444-4444-444444444444',
        'entregasTotales': 3,
        'entregasDelMes': 2,
        'tiempoPromedioEntregaMinutos': 21.5,
        'pedidosAsignadosActivos': 0,
        'cancelaciones': 0,
      })
      // 204 sin cuerpo: el backend no manda nada en aceptar ni completar.
      ..on('POST', '/delivery/d1/accept', '', statusCode: 204)
      ..on('POST', '/delivery/d1/complete', '', statusCode: 204);
  }

  Map<String, Object?> pedidoDisponible() => {
    'id': 'd1',
    'numeroPedido': 'QB-20260928-XX99YY',
    'estado': 'Listo',
    'total': 250.0,
    'creadoEn': '2026-09-28T14:30:00Z',
  };

  Map<String, Object?> pedidoEnCamino() => {
    'id': 'd1',
    'numeroPedido': 'QB-20260928-XX99YY',
    'estado': 'EnCamino',
    'total': 250.0,
    'creadoEn': '2026-09-28T14:30:00Z',
  };

  Future<void> entrar(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'luis@quickbite.mx',
    );
    await tester.enterText(find.byType(TextFormField).last, 'Password1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await asentar(tester);
  }

  testWidgets('el repartidor toma un pedido y lo completa', (tester) async {
    final app = await AppHarness.montar(tester);
    registrarBackendRepartidor(
      app,
      disponibles: [pedidoDisponible()],
      activos: [pedidoEnCamino()],
    );

    await entrar(tester);

    // 1. La sesión de repartidor aterriza en disponibles, no en el catálogo.
    expect(find.widgetWithText(AppBar, 'Pedidos disponibles'), findsOneWidget);
    expect(app.http.callsTo('GET', '/delivery/available'), greaterThan(0));
    expect(find.text('QB-20260928-XX99YY'), findsOneWidget);

    // 2. Aceptar pide confirmación y llama a la API.
    await tester.tap(find.text('Aceptar entrega').first);
    await asentar(tester);
    expect(find.text('¿Aceptar este pedido?'), findsOneWidget);

    await tester.tap(find.text('Aceptar').last);
    await asentar(tester);
    expect(app.http.callsTo('POST', '/delivery/d1/accept'), 1);
    expect(find.textContaining('asignado'), findsOneWidget);
    // El snackbar flota sobre la parte baja y se comería el toque del botón de
    // "Marcar como entregado", que también vive abajo.
    await tester.pump(const Duration(seconds: 5));

    // 3. La entrega activa se pide sola al cambiar de pestaña.
    await tester.tap(find.text('Entrega activa'));
    await asentar(tester);
    expect(app.http.callsTo('GET', '/delivery/active'), greaterThan(0));
    expect(find.text('Marcar como entregado'), findsOneWidget);

    // 4. Completar pide confirmación, llama a la API y devuelve a disponibles.
    await tester.tap(find.text('Marcar como entregado'));
    await asentar(tester);
    expect(find.text('¿Marcar como entregado?'), findsOneWidget);

    await tester.tap(find.text('Marcar como entregado').last);
    await asentar(tester);
    expect(app.http.callsTo('POST', '/delivery/d1/complete'), 1);
    expect(find.widgetWithText(AppBar, 'Pedidos disponibles'), findsOneWidget);

    // 5. El historial ya muestra la entrega.
    await tester.tap(find.text('Historial'));
    await asentar(tester);
    expect(find.text('QB-20260928-XX99YY'), findsOneWidget);
  });

  testWidgets('sin entrega activa, la pestaña devuelve a disponibles', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);
    registrarBackendRepartidor(app);

    await entrar(tester);

    await tester.tap(find.text('Entrega activa'));
    await asentar(tester);

    // 07.1 SCR-DEL-03: "Sin entrega activa → redirigir a disponibles".
    expect(find.widgetWithText(AppBar, 'Pedidos disponibles'), findsOneWidget);
    expect(find.text('No hay pedidos disponibles'), findsOneWidget);
  });

  testWidgets('el repartidor llega a sus estadísticas desde el perfil', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);
    registrarBackendRepartidor(app);
    app.http.on('GET', '/users/profile', {
      'id': '44444444-4444-4444-4444-444444444444',
      'nombre': 'Luis García',
      'email': 'luis@quickbite.mx',
      'rol': 'repartidor',
      'telefono': '5512345678',
    });

    await entrar(tester);

    // El shell de repartidor no tiene pestaña de perfil: se entra por el ícono
    // del encabezado de "Pedidos disponibles".
    await tester.tap(find.byTooltip('Perfil'));
    await asentar(tester);
    expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
    expect(find.text('Mis estadísticas'), findsOneWidget);

    await tester.tap(find.text('Mis estadísticas'));
    await asentar(tester);

    expect(find.widgetWithText(AppBar, 'Mis estadísticas'), findsOneWidget);
    expect(app.http.callsTo('GET', '/delivery/stats'), 1);
    expect(find.text('Entregas totales'), findsOneWidget);
    expect(find.text('23'), findsNothing);
    expect(find.text('21.5'), findsOneWidget);
  });

  testWidgets('el repartidor cambia su disponibilidad (07.1 SCR-DEL-07)', (
    tester,
  ) async {
    final app = await AppHarness.montar(tester);
    registrarBackendRepartidor(app);
    app.http
      ..on('GET', '/users/profile', {
        'id': '44444444-4444-4444-4444-444444444444',
        'nombre': 'Luis García',
        'email': 'luis@quickbite.mx',
        'rol': 'repartidor',
        'telefono': '5512345678',
      })
      // El repartidor arranca inactivo y el `GET` sigue devolviendo ese estado:
      // es el `PUT` el que lo cambia de verdad en el servidor, así que después
      // del cambio la consulta vuelve a ver "disponible".
      ..onSequence('GET', '/delivery/availability', [
        const FakeRoute(body: {'estado': 3, 'tieneEntregaActiva': false}),
        const FakeRoute(body: {'estado': 1, 'tieneEntregaActiva': false}),
      ])
      ..on('PUT', '/delivery/availability', {
        'estado': 1,
        'tieneEntregaActiva': false,
      });

    await entrar(tester);
    await tester.tap(find.byTooltip('Perfil'));
    await asentar(tester);
    await tester.tap(find.text('Disponibilidad'));
    await asentar(tester);

    expect(find.text('Estoy disponible para recibir pedidos'), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isFalse,
      reason: 'el repartidor arranca inactivo',
    );

    await tester.tap(find.byType(Switch));
    await asentar(tester);

    expect(app.http.callsTo('PUT', '/delivery/availability'), 1);
    final enviada = app.http.requestsTo('PUT', '/delivery/availability').single;
    // `estado` viaja como número: es el valor de `DeliveryPersonStatus` que
    // espera el backend, no el texto.
    expect(enviada.data, containsPair('estado', 1));
    expect(
      tester.widget<Switch>(find.byType(Switch)).value,
      isTrue,
      reason: 'la respuesta del servidor repinta el interruptor',
    );
  });
}

import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/checkout_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_list_providers.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_tracking_providers.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';
import 'package:quickbite_mobile/src/features/shell/app_router.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/order_fakes.dart';

const _session = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

const _enCurso = Order(
  id: 'o1',
  numeroPedido: 'QB-20260927-AB12CD',
  estado: 'Preparando',
  total: 171,
  direccionEntrega: '',
  items: [OrderItem(nombre: 'Tacos al pastor', cantidad: 2)],
  subtotal: 150,
  costoEnvio: 21,
  creadoEn: null,
);

const _entregado = Order(
  id: 'o2',
  numeroPedido: 'QB-20260920-ZZ99YY',
  estado: 'Entregado',
  total: 240,
  direccionEntrega: '',
  items: [OrderItem(nombre: 'Burrito de carnitas', cantidad: 1)],
  subtotal: 220,
  costoEnvio: 20,
);

const _cancelado = Order(
  id: 'o3',
  numeroPedido: 'QB-20260915-KK11LL',
  estado: 'Cancelado',
  total: 90,
  direccionEntrega: '',
  items: [OrderItem(nombre: 'Agua de horchata', cantidad: 1)],
);

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeOrderRepository orders;

  setUp(() {
    orders = FakeOrderRepository()
      ..pedidos = [_enCurso, _entregado, _cancelado];
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        // El detalle abre su propio polling: con un intervalo corto el
        // `pumpAndSettle` de la navegación nunca terminaría.
        intervaloPollingProvider.overrideWithValue(const Duration(minutes: 1)),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(() async => _session);
    router.go(location);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('formato de fecha (intl)', () {
    testWidgets('el historial muestra la fecha del pedido en español', (
      tester,
    ) async {
      orders.pedidos = [
        Order(
          id: 'o4',
          numeroPedido: 'QB-CON-FECHA',
          estado: 'Entregado',
          total: 100,
          direccionEntrega: '',
          items: const [],
          creadoEn: DateTime.utc(2026, 9, 20, 15, 30),
        ),
      ];

      await pumpAt(tester, '/history');

      // `DateFormat(..., 'es')` sin `initializeDateFormatting` lanza
      // LocaleDataException y la pantalla se queda en rojo.
      expect(find.textContaining('2026'), findsOneWidget);
    });
  });

  group('ordersProvider', () {
    test('trae el historial del cliente', () async {
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(orders)],
      );
      addTearDown(container.dispose);

      final lista = await container.read(ordersProvider.future);

      expect(lista, hasLength(3));
    });

    test('el filtro inicial es "Todos"', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(orderFilterProvider), FiltroPedido.todos);
    });

    test('el filtrado es en cliente sobre los estados del filtro', () async {
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(orders)],
      );
      addTearDown(container.dispose);

      container
          .read(orderFilterProvider.notifier)
          .seleccionar(FiltroPedido.entregados);
      final lista = await container.read(ordersProvider.future);

      expect(container.read(ordersFiltradosProvider).map((o) => o.id), [
        _entregado.id,
      ]);
      expect(lista, hasLength(3), reason: 'la API no filtra, la app sí');
    });

    test('el filtro "En curso" excluye entregados y cancelados', () async {
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(orders)],
      );
      addTearDown(container.dispose);
      await container.read(ordersProvider.future);

      container
          .read(orderFilterProvider.notifier)
          .seleccionar(FiltroPedido.enCurso);

      expect(container.read(ordersFiltradosProvider).map((o) => o.id), [
        _enCurso.id,
      ]);
    });
  });

  group('OrdersScreen (07.1 SCR-ORDER-03)', () {
    testWidgets('muestra un resumen por pedido con número, estado y total', (
      tester,
    ) async {
      await pumpAt(tester, '/history');

      expect(find.text('QB-20260927-AB12CD'), findsOneWidget);
      expect(find.text('QB-20260920-ZZ99YY'), findsOneWidget);
      expect(find.text('Preparando'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text(r'$171.00'), findsOneWidget);
    });

    testWidgets('ofrece los cinco chips de filtro del historial', (
      tester,
    ) async {
      await pumpAt(tester, '/history');

      for (final etiqueta in FiltroPedido.values.map((f) => f.etiqueta)) {
        expect(find.text(etiqueta), findsOneWidget);
      }
    });

    testWidgets('los chips de filtro se muestran enteros, sin recorte', (
      tester,
    ) async {
      // La fila de filtros tenía un alto fijo (56 px) que ya incluía el padding
      // vertical de la propia lista, así que al chip le quedaban 24 px de los 37
      // que necesita: su etiqueta se estrujaba a 6 px y quedaba reducida a un
      // trazo. En modo claro eso se lee como "texto invisible".
      await pumpAt(tester, '/history');

      final chipEnFiltros = tester.getSize(
        find
            .ancestor(
              of: find.text('Pendientes'),
              matching: find.byType(CategoryChip),
            )
            .first,
      );

      // Referencia: el mismo chip, sin la restricción de alto de la fila.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CategoryChip(
                label: 'Pendientes',
                selected: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chipNatural = tester.getSize(find.byType(CategoryChip));

      expect(
        chipEnFiltros.height,
        chipNatural.height,
        reason:
            'la píldora se comprime a ${chipEnFiltros.height} px de los '
            '${chipNatural.height} px que necesita, y su texto se corta',
      );
    });

    testWidgets('al elegir un chip solo quedan los pedidos de ese estado', (
      tester,
    ) async {
      await pumpAt(tester, '/history');

      await tester.tap(find.text('Entregados'));
      await tester.pumpAndSettle();

      expect(find.text('QB-20260920-ZZ99YY'), findsOneWidget);
      expect(find.text('QB-20260927-AB12CD'), findsNothing);
      expect(find.text('QB-20260915-KK11LL'), findsNothing);
    });

    testWidgets('un filtro sin resultados explica que no hay pedidos', (
      tester,
    ) async {
      orders.pedidos = [_entregado];
      await pumpAt(tester, '/history');

      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No tienes pedidos'), findsOneWidget);
    });

    testWidgets('sin pedidos muestra el estado vacío del design system', (
      tester,
    ) async {
      orders.pedidos = [];
      await pumpAt(tester, '/history');

      expect(find.textContaining('No tienes pedidos'), findsOneWidget);
      // 09 §8.6: tarjeta con elevación 1 y esquinas de 16 px, igual que el
      // carrito, para que "vacío" signifique lo mismo en toda la app.
      final tarjeta = tester.widget<Card>(find.byType(Card).first);
      expect(tarjeta.elevation, 1);
      expect(
        (tarjeta.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.card),
      );
    });

    testWidgets('un error muestra el mensaje y reintenta', (tester) async {
      orders.listError = const ServerException(
        'No pudimos cargar tus pedidos.',
      );
      await pumpAt(tester, '/history');

      expect(find.textContaining('No pudimos cargar'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('tocar un pedido abre su detalle', (tester) async {
      await pumpAt(tester, '/history');

      await tester.tap(find.text('QB-20260927-AB12CD'));
      // El detalle arranca su polling: `pumpAndSettle` nunca termina.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('2 × Tacos al pastor'), findsOneWidget);
    });
  });
}

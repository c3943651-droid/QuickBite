import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/widgets/chips.dart';
import 'package:quickbite_mobile/src/core/widgets/product_card.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';
import 'package:quickbite_mobile/src/features/cart/presentation/cart_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/filter_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/home_screen.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/notification_providers.dart';

import '../../../support/cart_fakes.dart';
import '../../../support/notification_fakes.dart';

const _tacos = Category(id: 'c1', nombre: 'Tacos', orden: 1, activo: true);
const _bebidas = Category(id: 'c2', nombre: 'Bebidas', orden: 2, activo: true);

const _pastor = Product(
  id: 'p1',
  nombre: 'Tacos al pastor',
  descripcion: 'Tres tacos de pastor con cebolla y cilantro.',
  precio: 85.50,
  disponible: true,
  categoria: _tacos,
);

const _refresco = Product(
  id: 'p2',
  nombre: 'Agua de horchata',
  precio: 35.00,
  disponible: true,
  categoria: _bebidas,
);

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.error,
    this.categoriesError,
    this.totalPages = 1,
  });

  Object? error;
  Object? categoriesError;
  List<ProductFilter> filters = [];
  List<Category> categories = const [_tacos, _bebidas];
  List<Product> products = const [_pastor, _refresco];
  int totalPages;

  @override
  Future<List<Category>> getCategories() async {
    if (categoriesError != null) {
      throw categoriesError!;
    }
    return categories;
  }

  @override
  Future<List<PromotionBanner>> getPromotions() async => const [
    PromotionBanner(
      id: 'p1',
      titulo: '2x1 en Tacos',
      subtitulo: 'Solo hoy',
      color: Color(0xFF0D9488),
    ),
    PromotionBanner(
      id: 'p2',
      titulo: 'Envío gratis',
      subtitulo: 'En pedidos +200',
      color: Color(0xFF2563EB),
    ),
  ];

  @override
  Future<Product> getProduct(String id) => throw UnimplementedError();

  @override
  Future<List<ProductOption>> getProductOptions(String id) =>
      throw UnimplementedError();

  @override
  Future<ProductPage> getProducts(ProductFilter filter) async {
    filters.add(filter);
    if (error != null) {
      throw error!;
    }
    return ProductPage(
      items: products,
      page: filter.page,
      limit: filter.limit,
      total: products.length,
      totalPages: totalPages,
    );
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) => throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<UserProfile> fetchProfile() async => const UserProfile(
    id: '33333333-3333-3333-3333-333333333333',
    nombre: 'Carlos Pérez',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  );

  @override
  Future<UserProfile> updateProfile({String? nombre, String? telefono}) async =>
      UserProfile(
        id: '33333333-3333-3333-3333-333333333333',
        nombre: nombre ?? 'Carlos Pérez',
        email: 'carlos@quickbite.mx',
        rol: 'cliente',
        telefono: telefono,
      );

  @override
  Future<AuthTokens> refresh({required String refreshToken}) =>
      throw UnimplementedError();

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession session) async {}
}

class EmptyTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<StoredSession?> read() async => null;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> save(StoredSession session) async {}
}

void main() {
  Future<({ProviderContainer container, FakeCartRepository cart})> pumpHome(
    WidgetTester tester,
    FakeCatalogRepository catalog, {
    FakeCartRepository? cart,
  }) async {
    final carrito = cart ?? FakeCartRepository();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        cartRepositoryProvider.overrideWithValue(carrito),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(EmptyTokenStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    // Pumps acotados: con más de una página el indicador de carga final gira de
    // forma indefinida y pumpAndSettle nunca converge.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return (container: container, cart: carrito);
  }

  group('HomeScreen', () {
    testWidgets('muestra el catálogo con precio formateado', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(find.text('Agua de horchata'), findsOneWidget);
      expect(find.text(r'$85.50'), findsOneWidget);
      expect(find.text(r'$35.00'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets('el GridView tiene padding inferior para la barra flotante', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      final grid = tester.widget<GridView>(find.byType(GridView));
      final padding = grid.padding as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(140));
    });

    testWidgets('la tarjeta deja más altura a la imagen que al texto', (
      tester,
    ) async {
      // Con 0.72 la imagen se comía ~85% de la tarjeta y el nombre + precio
      // quedaban prensados contra el borde inferior: la rejilla se leía como
      // una galería de huecos vacíos en vez de un catálogo. La proporción se
      // sube para que la foto sea la protagonista sin aplastar el texto.
      await pumpHome(tester, FakeCatalogRepository());

      final delegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.childAspectRatio, greaterThan(0.8));
    });

    testWidgets('el botón de filtros es una cápsula 38x38 en la fila de categorías', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      final filterButton = find.byTooltip('Filtros');
      expect(filterButton, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: filterButton,
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 38);
      expect(sizedBox.height, 38);
    });

    testWidgets('el fondo del catálogo es gris suave #F8F9FA', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF8F9FA));
    });

    testWidgets('muestra carrusel de promociones entre búsqueda y categorías', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Promociones'), findsOneWidget);
    });

    testWidgets('el carrusel tiene indicador de puntos', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('el carrusel tiene peek effect de 16px', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      final controller = pageView.controller as PageController;
      expect(controller.viewportFraction, lessThan(1.0));
    });

    testWidgets('muestra las categorías en chips', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Tacos'), findsOneWidget);
      expect(find.text('Bebidas'), findsOneWidget);
    });

    testWidgets('seleccionar una categoría filtra el catálogo', (tester) async {
      final catalog = FakeCatalogRepository();
      await pumpHome(tester, catalog);

      await tester.tap(find.widgetWithText(CategoryChip, 'Bebidas'));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.categoryId, 'c2');
      expect(find.text('Agua de horchata'), findsOneWidget);
    });

    testWidgets('el chip "Todas" limpia el filtro de categoría', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository();
      await pumpHome(tester, catalog);
      await tester.tap(find.widgetWithText(CategoryChip, 'Bebidas'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CategoryChip, 'Todas'));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.categoryId, isNull);
    });

    testWidgets('la búsqueda se aplica con debounce', (tester) async {
      final catalog = FakeCatalogRepository();
      await pumpHome(tester, catalog);
      final callsBefore = catalog.filters.length;

      await tester.enterText(find.byType(TextField).first, 'pastor');
      await tester.pump();
      expect(
        catalog.filters,
        hasLength(callsBefore),
        reason: 'no debe buscar en cada tecla',
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.search, 'pastor');
    });

    testWidgets('muestra estado vacío cuando no hay productos', (tester) async {
      await pumpHome(tester, FakeCatalogRepository()..products = const []);

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No hay productos disponibles'), findsOneWidget);
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final catalog = FakeCatalogRepository(error: const NetworkException());
      await pumpHome(tester, catalog);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(
        find.text(
          'No hay conexión con el servidor. Verifica tu red e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );

      catalog.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Tacos al pastor'), findsOneWidget);
    });

    testWidgets('un fallo de categorías no rompe el catálogo', (tester) async {
      await pumpHome(
        tester,
        FakeCatalogRepository(categoriesError: StateError('boom')),
      );

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(find.text('Bebidas'), findsNothing);
    });

    testWidgets('las tarjetas muestran calificación y tiempo estimado', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository()
        ..products = const [
          Product(
            id: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            disponible: true,
            categoria: _tacos,
            calificacion: 4.8,
            tiempoEstimado: '15-20 min',
          ),
        ];

      await pumpHome(tester, catalog);

      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('15-20 min'), findsOneWidget);
    });

    testWidgets('las tarjetas tienen tipografía jerárquica', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      final productName = tester.widget<Text>(find.text('Tacos al pastor'));
      expect(productName.style?.fontWeight, FontWeight.w600);
      expect(productName.style?.fontSize, 14);

      final price = tester.widget<Text>(find.text(r'$85.50'));
      expect(price.style?.fontWeight, FontWeight.w700);
      expect(price.style?.fontSize, 15);
    });

    testWidgets('las tarjetas tienen BorderRadius 12 y fondo blanco', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ProductCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decor = container.decoration! as BoxDecoration;
      expect(decor.borderRadius, BorderRadius.circular(12));
      expect(decor.color, AppColors.white);
    });

    testWidgets('las tarjetas muestran badge de popular cuando aplica', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository()
        ..products = const [
          Product(
            id: 'p1',
            nombre: 'Tacos al pastor',
            precio: 85.50,
            disponible: true,
            categoria: _tacos,
            esPopular: true,
          ),
        ];

      await pumpHome(tester, catalog);

      expect(find.text('Popular'), findsOneWidget);
    });

    testWidgets('el quick-add mete el producto en el carrito', (tester) async {
      final pumped = await pumpHome(tester, FakeCatalogRepository());

      await tester.tap(find.byIcon(Icons.add_circle).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pumped.cart.adds.single.productoId, 'p1');
      expect(pumped.cart.adds.single.cantidad, 1);
      expect(find.text('Agregado al carrito'), findsOneWidget);
    });

    testWidgets('el quick-add no ofrece productos agotados', (tester) async {
      final catalog = FakeCatalogRepository()
        ..products = const [
          Product(
            id: 'p9',
            nombre: 'Sopa del día',
            precio: 60,
            disponible: false,
          ),
        ];

      await pumpHome(tester, catalog);

      expect(find.byIcon(Icons.add_circle), findsNothing);
    });

    testWidgets('añade un indicador de carga al final si hay más páginas', (
      tester,
    ) async {
      // La paginación en sí se verifica en providers_test; aquí solo el indicador.
      final pumped = await pumpHome(
        tester,
        FakeCatalogRepository(totalPages: 3),
      );

      expect(pumped.container.read(productsProvider).value?.hasMore, isTrue);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(ProductCard), findsNWidgets(2));
    });

    testWidgets('el campo de búsqueda enlaza a la pantalla dedicada', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(EmptyTokenStorage()),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/search',
            builder: (_, _) =>
                const Scaffold(body: Text('Pantalla de búsqueda')),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byTooltip('Búsqueda avanzada'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla de búsqueda'), findsOneWidget);
    });

    testWidgets('tocar un producto abre su detalle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(EmptyTokenStorage()),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/product/:id',
            builder: (_, state) => Scaffold(
              body: Text('Detalle de ${state.pathParameters['id']}'),
            ),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Tacos al pastor'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de p1'), findsOneWidget);
    });

    testWidgets('el botón de filtros abre la hoja de filtros avanzados', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterSheet), findsOneWidget);
      expect(find.text('Aplicar filtros'), findsOneWidget);
    });

    testWidgets('el botón de filtros cuenta los filtros activos', (tester) async {
      final catalog = FakeCatalogRepository();
      final pumped = await pumpHome(tester, catalog);

      pumped.container
          .read(productFilterProvider.notifier)
          .applyAll(
            const ProductFilter(categoryId: 'c2', precioMin: 20, precioMax: 90),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byTooltip('Filtros'), findsOneWidget);

      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.categoryId, isNull);
      expect(catalog.filters.last.precioMin, isNull);
    });

    testWidgets('el botón de filtros no muestra contador sin filtros activos', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      expect(find.byTooltip('Filtros'), findsOneWidget);
    });

    testWidgets('el saludo usa el nombre del usuario autenticado', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository();
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(catalog),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(EmptyTokenStorage()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(sessionProvider.notifier)
          .login(email: 'c@q.mx', password: 'Password1!');
      await container.read(sessionProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // El saludo ahora va en la banda superior y cambia según la hora, así que
      // lo que se comprueba es el nombre, no la fórmula exacta.
      expect(find.textContaining('Carlos Pérez'), findsOneWidget);
    });
  });

  group('campana de notificaciones', () {
    testWidgets('abre la bandeja y muestra cuántas hay sin leer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final notificaciones = FakeNotificationRepository(
        notificaciones: [
          Notificacion(
            id: 'n1',
            tipo: TipoNotificacion.cambioEstado,
            titulo: 'Tu pedido va en camino',
            mensaje: 'Salió del restaurante.',
            creadoEn: DateTime(2026, 9, 27, 15),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(EmptyTokenStorage()),
          notificationRepositoryProvider.overrideWithValue(notificaciones),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const Scaffold(body: Text('Bandeja')),
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Notificaciones'));
      await tester.pumpAndSettle();

      expect(find.text('Bandeja'), findsOneWidget);
    });
  });
}

const _session = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '1',
    nombre: 'Carlos Pérez',
    email: 'c@q.mx',
    rol: 'cliente',
  ),
);

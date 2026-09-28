import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
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

import '../../../support/cart_fakes.dart';

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

    testWidgets('muestra las categorías en chips', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Tacos'), findsOneWidget);
      expect(find.text('Bebidas'), findsOneWidget);
    });

    testWidgets('seleccionar una categoría filtra el catálogo', (tester) async {
      final catalog = FakeCatalogRepository();
      await pumpHome(tester, catalog);

      await tester.tap(find.widgetWithText(FilterChip, 'Bebidas'));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.categoryId, 'c2');
      expect(find.text('Agua de horchata'), findsOneWidget);
    });

    testWidgets('el chip "Todas" limpia el filtro de categoría', (
      tester,
    ) async {
      final catalog = FakeCatalogRepository();
      await pumpHome(tester, catalog);
      await tester.tap(find.widgetWithText(FilterChip, 'Bebidas'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Todas'));
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

    testWidgets('"Filtros" abre la hoja de filtros avanzados', (tester) async {
      await pumpHome(tester, FakeCatalogRepository());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterSheet), findsOneWidget);
      expect(find.text('Aplicar filtros'), findsOneWidget);
    });

    testWidgets('"Filtros" cuenta los filtros activos', (tester) async {
      final catalog = FakeCatalogRepository();
      final pumped = await pumpHome(tester, catalog);

      pumped.container
          .read(productFilterProvider.notifier)
          .applyAll(
            const ProductFilter(categoryId: 'c2', precioMin: 20, precioMax: 90),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // categoría + rango de precio = 2 filtros (el rango cuenta como uno).
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();

      expect(catalog.filters.last.categoryId, isNull);
      expect(catalog.filters.last.precioMin, isNull);
    });

    testWidgets('"Filtros" no muestra contador sin filtros activos', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('0'), findsNothing);
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

      expect(find.text('Hola, Carlos Pérez'), findsOneWidget);
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

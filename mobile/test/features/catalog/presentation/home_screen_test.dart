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
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/home_screen.dart';

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
  Future<ProviderContainer> pumpHome(
    WidgetTester tester,
    FakeCatalogRepository catalog,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
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
    return container;
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

    testWidgets('el quick-add no promete un carrito inexistente', (
      tester,
    ) async {
      await pumpHome(tester, FakeCatalogRepository());

      await tester.tap(find.byIcon(Icons.add_circle).first);
      await tester.pump();

      expect(
        find.text('El carrito llegará en el próximo hito.'),
        findsOneWidget,
      );
      expect(find.text('Agregado al carrito'), findsNothing);
    });

    testWidgets('añade un indicador de carga al final si hay más páginas', (
      tester,
    ) async {
      // La paginación en sí se verifica en providers_test; aquí solo el indicador.
      final container = await pumpHome(
        tester,
        FakeCatalogRepository(totalPages: 3),
      );

      expect(container.read(productsProvider).value?.hasMore, isTrue);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(ProductCard), findsNWidgets(2));
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

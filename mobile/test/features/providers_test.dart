import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';

class StubCatalogRepository implements CatalogRepository {
  List<ProductFilter> productFilters = [];
  int getCategoriesCalls = 0;

  List<Product> products = const [];
  List<Category> categories = const [];
  Object? error;

  @override
  Future<List<Category>> getCategories() async {
    getCategoriesCalls++;
    if (error != null) {
      throw error!;
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
    productFilters.add(filter);
    if (error != null) {
      throw error!;
    }
    return ProductPage(
      items: products,
      page: filter.page,
      limit: filter.limit,
      total: products.length,
      totalPages: products.length > filter.page ? 2 : 1,
    );
  }
}

ProviderContainer buildContainer(StubCatalogRepository catalog) {
  final container = ProviderContainer(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(catalog),
      tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _EmptyTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<StoredSession?> read() async => null;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> save(StoredSession session) async {}
}

const _taco = Product(id: '1', nombre: 'Taco', precio: 20, disponible: true);
const _burrito = Product(
  id: '2',
  nombre: 'Burrito',
  precio: 40,
  disponible: true,
);
const _tacos = Category(id: 'c1', nombre: 'Tacos', orden: 1, activo: true);

void main() {
  group('categoriesProvider', () {
    test('expone las categorías del repositorio', () async {
      final catalog = StubCatalogRepository()..categories = const [_tacos];
      final container = buildContainer(catalog);

      final categories = await container.read(categoriesProvider.future);

      expect(categories, [_tacos]);
      expect(catalog.getCategoriesCalls, 1);
    });

    test('propaga el error como AsyncError', () async {
      final catalog = StubCatalogRepository()..error = StateError('boom');
      final container = buildContainer(catalog);

      await expectLater(
        container.read(categoriesProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ProductFilterNotifier', () {
    test('seleccionar categoría reinicia la página', () {
      final catalog = StubCatalogRepository();
      final container = buildContainer(catalog);

      container.read(productFilterProvider.notifier).selectCategory('c1');

      expect(container.read(productFilterProvider).categoryId, 'c1');
      expect(container.read(productFilterProvider).page, 1);
    });

    test('seleccionar null limpia la categoría', () {
      final container = buildContainer(StubCatalogRepository());
      container.read(productFilterProvider.notifier).selectCategory('c1');

      container.read(productFilterProvider.notifier).selectCategory(null);

      expect(container.read(productFilterProvider).categoryId, isNull);
    });

    test('search y sort reinician la página y conservan la categoría', () {
      final container = buildContainer(StubCatalogRepository());
      container.read(productFilterProvider.notifier).selectCategory('c1');
      container.read(productFilterProvider.notifier).search('pastor');
      container
          .read(productFilterProvider.notifier)
          .setSort(ProductSort.precioDesc);

      final filter = container.read(productFilterProvider);
      expect(filter.search, 'pastor');
      expect(filter.sort, ProductSort.precioDesc);
      expect(filter.categoryId, 'c1');
      expect(filter.page, 1);
    });

    test('clear vuelve al filtro inicial', () {
      final container = buildContainer(StubCatalogRepository());
      container.read(productFilterProvider.notifier).search('pastor');
      container
          .read(productFilterProvider.notifier)
          .setSort(ProductSort.nombreDesc);

      container.read(productFilterProvider.notifier).clear();

      expect(container.read(productFilterProvider), const ProductFilter());
    });
  });

  group('productsProvider', () {
    test('carga la primera página con el filtro activo', () async {
      final catalog = StubCatalogRepository()
        ..products = const [_taco, _burrito];
      final container = buildContainer(catalog);

      final page = await container.read(productsProvider.future);

      expect(page.items, [_taco, _burrito]);
      expect(catalog.productFilters.single.page, 1);
    });

    test('cambiar el filtro dispara una recarga', () async {
      final catalog = StubCatalogRepository()..products = const [_taco];
      final container = buildContainer(catalog);
      await container.read(productsProvider.future);

      container.read(productFilterProvider.notifier).selectCategory('c1');
      await container.read(productsProvider.future);

      expect(catalog.productFilters, hasLength(2));
      expect(catalog.productFilters.last.categoryId, 'c1');
    });

    test(
      'loadMore concatena la siguiente página y actualiza la página actual',
      () async {
        final catalog = StubCatalogRepository()
          ..products = const [_taco, _burrito];
        final container = buildContainer(catalog);
        await container.read(productsProvider.future);

        await container.read(productsProvider.notifier).loadMore();

        final state = container.read(productsProvider);
        expect(state.requireValue.page, 2);
        expect(catalog.productFilters.last.page, 2);
      },
    );

    test('loadMore no hace nada si no hay más páginas', () async {
      final catalog = StubCatalogRepository()..products = const [_taco];
      final container = buildContainer(catalog);
      await container.read(productsProvider.future);
      final callsBefore = catalog.productFilters.length;

      await container.read(productsProvider.notifier).loadMore();

      expect(catalog.productFilters, hasLength(callsBefore));
    });

    test('loadMore conserva lo cargado si la siguiente página falla', () async {
      final catalog = StubCatalogRepository()
        ..products = const [_taco, _burrito];
      final container = buildContainer(catalog);
      await container.read(productsProvider.future);

      catalog.error = StateError('fallo de red');
      await container.read(productsProvider.notifier).loadMore();

      final state = container.read(productsProvider);
      expect(state.hasError, isFalse);
      expect(state.requireValue.items, [_taco, _burrito]);
    });

    test(
      'refresh conserva la vista con datos y vuelve a pedir la primera página',
      () async {
        final catalog = StubCatalogRepository()..products = const [_taco];
        final container = buildContainer(catalog);
        await container.read(productsProvider.future);

        await container.read(productsProvider.notifier).refresh();

        expect(catalog.productFilters.last.page, 1);
        expect(container.read(productsProvider).requireValue.items, [_taco]);
      },
    );
  });

  group('sessionProvider', () {
    test('arranca sin sesión si no hay tokens guardados', () async {
      final container = buildContainer(StubCatalogRepository());

      expect(await container.read(sessionProvider.future), isNull);
    });

    test('el login publica la sesión y la persiste', () async {
      final repository = _RecordingAuthRepository();
      final isolated = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(isolated.dispose);

      await isolated
          .read(sessionProvider.notifier)
          .login(email: 'carlos@quickbite.mx', password: 'Password1!');

      final session = isolated.read(sessionProvider).requireValue;
      expect(session?.user.email, 'carlos@quickbite.mx');
      expect(session?.user.isCliente, isTrue);
      expect(repository.persisted, isTrue);
    });

    test('el login fallido deja la sesión en error', () async {
      final repository = _RecordingAuthRepository(
        error: const UnauthorizedException(),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(sessionProvider.notifier)
          .login(email: 'malo@q.mx', password: 'x');

      expect(container.read(sessionProvider).hasError, isTrue);
    });

    test('logout limpia siempre la sesión local', () async {
      final repository = _RecordingAuthRepository(logoutThrows: true);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(sessionProvider.notifier)
          .login(email: 'c@q.mx', password: 'Password1!');

      await container.read(sessionProvider.notifier).logout();

      expect(container.read(sessionProvider).requireValue, isNull);
    });

    test('registro exitoso no deja sesión iniciada', () async {
      final repository = _RecordingAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(sessionProvider.notifier)
          .register(
            nombre: 'Carlos',
            email: 'c@q.mx',
            password: 'Password1!',
            rol: 'cliente',
          );

      expect(repository.registerRol, 'cliente');
      expect(container.read(sessionProvider).requireValue, isNull);
    });
  });
  group('política de reintentos', () {
    test('productsProvider no reintenta solo tras un error', () async {
      final catalog = StubCatalogRepository()..error = const NetworkException();
      final container = ProviderContainer(
        overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
      );
      addTearDown(container.dispose);

      await container
          .read(productsProvider.future)
          .then((_) {}, onError: (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(
        catalog.productFilters,
        hasLength(1),
        reason: 'el reintento debe ser explícito del usuario',
      );
      expect(container.read(productsProvider).hasError, isTrue);
      expect(container.read(productsProvider).isLoading, isFalse);
    });

    test('categoriesProvider no reintenta solo tras un error', () async {
      final catalog = StubCatalogRepository()..error = const NetworkException();
      final container = ProviderContainer(
        overrides: [catalogRepositoryProvider.overrideWithValue(catalog)],
      );
      addTearDown(container.dispose);

      await container
          .read(categoriesProvider.future)
          .then((_) {}, onError: (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(catalog.getCategoriesCalls, 1);
      expect(container.read(categoriesProvider).hasError, isTrue);
    });
  });
}

const _session = AuthSession(
  tokens: AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600),
  user: AuthUser(
    id: '1',
    nombre: 'Carlos',
    email: 'carlos@quickbite.mx',
    rol: 'cliente',
  ),
);

class _RecordingAuthRepository implements AuthRepository, TokenStorage {
  _RecordingAuthRepository({this.error, this.logoutThrows = false});

  final Object? error;
  final bool logoutThrows;
  bool persisted = false;
  String? registerRol;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (error != null) {
      throw error!;
    }
    return _session;
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    if (logoutThrows) {
      throw StateError('el backend falló');
    }
  }

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async =>
      _session.tokens;

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {
    registerRol = rol;
    if (error != null) {
      throw error!;
    }
  }

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession session) async => persisted = true;

  @override
  Future<void> clear() async {}

  @override
  Future<StoredSession?> read() async => null;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> save(StoredSession session) async {}
}

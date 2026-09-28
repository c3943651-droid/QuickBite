import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/core/widgets/state_views.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_repository.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';
import 'package:quickbite_mobile/src/features/catalog/presentation/catalog_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/catalog_fakes.dart';
import '../../../support/fake_token_storage.dart';

class _SearchCatalogRepository implements CatalogRepository {
  List<Product> matches = const [quickbitePastor];
  Object? error;
  final List<ProductFilter> filters = [];

  @override
  Future<List<Category>> getCategories() async => const [quickbiteTacos];

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
      items: matches,
      page: filter.page,
      limit: filter.limit,
      total: matches.length,
      totalPages: 1,
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile> fetchProfile() async => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({String? nombre, String? telefono}) async =>
      throw UnimplementedError();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    required String rol,
  }) async {}

  @override
  Future<void> forgotPassword({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async =>
      const AuthTokens(accessToken: 'a', refreshToken: 'r', expiresIn: 3600);

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<StoredSession?> restoreSession() async => null;

  @override
  Future<void> persistSession(AuthSession session) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SearchCatalogRepository catalog;

  setUp(() {
    catalog = _SearchCatalogRepository();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSearch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSearchWithRouter(
    WidgetTester tester,
    GoRouter router,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);

    router.go('/search');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField searchField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  group('SearchScreen (07.1 SCR-CAT-02)', () {
    testWidgets('sin escribir, muestra el historial reciente', (tester) async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['tacos', 'pastor', 'refrescos'],
      });

      await pumpSearch(tester);

      expect(find.text('Búsquedas recientes'), findsOneWidget);
      expect(find.text('tacos'), findsOneWidget);
      expect(find.text('pastor'), findsOneWidget);
      expect(find.text('refrescos'), findsOneWidget);
    });

    testWidgets('sin historial no muestra la sección de recientes', (
      tester,
    ) async {
      await pumpSearch(tester);

      expect(find.text('Búsquedas recientes'), findsNothing);
    });

    testWidgets('el campo de búsqueda tiene foco automático', (tester) async {
      await pumpSearch(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode?.hasFocus, isTrue);
    });

    testWidgets('escribir consulta con debounce de 300 ms', (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'pas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(catalog.filters, isEmpty, reason: 'filtra antes de los 300 ms');

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(catalog.filters, hasLength(1));
      expect(catalog.filters.single.search, 'pas');
    });

    testWidgets('un término del historial repite la búsqueda', (tester) async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['tacos'],
      });
      await pumpSearch(tester);

      await tester.tap(find.text('tacos'));
      await tester.pumpAndSettle();

      expect(catalog.filters.single.search, 'tacos');
      expect(searchField(tester).controller?.text, 'tacos');
    });

    testWidgets('borrar una entrada quita solo ese término', (tester) async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['tacos', 'pastor'],
      });
      await pumpSearch(tester);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('tacos'), findsNothing);
      expect(find.text('pastor'), findsOneWidget);
    });

    testWidgets('"Borrar historial" pide confirmación y vacía', (tester) async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['tacos', 'pastor'],
      });
      await pumpSearch(tester);

      await tester.tap(find.text('Borrar historial'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('tacos'), findsOneWidget);

      await tester.tap(find.text('Borrar historial'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('tacos'), findsNothing);
      expect(find.text('Búsquedas recientes'), findsNothing);
    });

    testWidgets('muestra los resultados que coinciden', (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'tacos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Tacos al pastor'), findsOneWidget);
      expect(find.text(r'$85.50'), findsOneWidget);
    });

    testWidgets('tocar un resultado navega al detalle del producto', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(
            path: '/product/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Detalle ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await pumpSearchWithRouter(tester, router);

      await tester.enterText(find.byType(TextField), 'tacos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tacos al pastor'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle p1'), findsOneWidget);
    });

    testWidgets('el error de búsqueda usa ErrorStateView con reintentar', (
      tester,
    ) async {
      catalog.error = Exception('boom');
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'tacos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('sin resultados muestra el mensaje de búsqueda vacía', (
      tester,
    ) async {
      catalog.matches = const [];
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No encontramos productos'), findsOneWidget);
    });

    testWidgets('el error de búsqueda ofrece reintentar', (tester) async {
      catalog.error = Exception('boom');
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'tacos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);

      catalog.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Tacos al pastor'), findsOneWidget);
    });

    testWidgets('el texto limpio no consulta la API', (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'tacos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      final calls = catalog.filters.length;

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(searchField(tester).controller?.text, isEmpty);
      expect(catalog.filters, hasLength(calls));
    });

    testWidgets('el historial se persiste al buscar', (tester) async {
      await pumpSearch(tester);

      await tester.enterText(find.byType(TextField), 'refrescos');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList('quickbite_search_history'), [
        'refrescos',
      ]);
    });
  });
}

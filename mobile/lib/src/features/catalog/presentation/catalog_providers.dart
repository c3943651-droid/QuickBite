import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/retry_policy.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/catalog_remote_data_source.dart';
import '../data/catalog_repository_impl.dart';
import '../domain/catalog_entities.dart';
import '../domain/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    CatalogRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).getCategories(),
  retry: noAutoRetry,
);

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void selectCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
      page: 1,
    );
  }

  void search(String term) {
    state = state.copyWith(search: term, page: 1);
  }

  void setSort(ProductSort sort) {
    state = state.copyWith(sort: sort, page: 1);
  }

  void clear() {
    state = const ProductFilter();
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, ProductPage>(
  ProductsNotifier.new,
  retry: noAutoRetry,
);

class ProductsNotifier extends AsyncNotifier<ProductPage> {
  ProductFilter _filter = const ProductFilter();
  bool _loadingMore = false;

  bool get isLoadingMore => _loadingMore;

  @override
  Future<ProductPage> build() async {
    _filter = ref.watch(productFilterProvider);
    return ref
        .watch(catalogRepositoryProvider)
        .getProducts(_filter.copyWith(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .getProducts(_filter.copyWith(page: current.page + 1));
      state = AsyncData(current.merge(next));
    } on Object {
      // La paginación se reintentará en el próximo scroll; no se descarta lo ya cargado.
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref
          .read(catalogRepositoryProvider)
          .getProducts(_filter.copyWith(page: 1)),
    );
  }
}

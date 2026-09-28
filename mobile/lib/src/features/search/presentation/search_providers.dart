import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/retry_policy.dart';
import '../../../core/session/token_storage.dart';
import '../../catalog/domain/catalog_entities.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../data/search_history_repository.dart';
import '../domain/search_history.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) =>
  throw UnimplementedError('tokenStorageProvider sin sobrescribir'),
);

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return SQLiteSearchHistoryRepository(ref.watch(tokenStorageProvider));
});

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, SearchHistory>(
      SearchHistoryNotifier.new,
      retry: noAutoRetry,
    );

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistoryNotifier, SearchHistory>(
      SearchHistoryNotifier.new,
      retry: noAutoRetry,
    );

class SearchHistoryNotifier extends AsyncNotifier<SearchHistory> {
  @override
  Future<SearchHistory> build() =>
      ref.watch(searchHistoryRepositoryProvider).read();

  /// 07.1 SCR-CAT-02 guarda la búsqueda al escribirla, no al abrir el resultado.
  Future<void> remember(String term) async {
    final current = state.value ?? const SearchHistory.empty();
    final next = current.withTerm(term);
    if (next == current) {
      return;
    }
    final repository = ref.read(searchHistoryRepositoryProvider);
    await repository.save(next);
    state = AsyncData(next);
  }

  Future<void> remove(String term) async {
    final repository = ref.read(searchHistoryRepositoryProvider);
    await repository.remove(term);
    state = AsyncData(
      (state.value ?? const SearchHistory.empty()).withoutTerm(term),
    );
  }

  Future<void> clear() async {
    await ref.read(searchHistoryRepositoryProvider).clear();
    state = const AsyncData(SearchHistory.empty());
  }
}

@immutable
class SearchResultsState {
  const SearchResultsState({
    this.term = '',
    this.page,
    this.loading = false,
    this.error,
  });

  final String term;
  final ProductPage? page;
  final bool loading;
  final Object? error;

  bool get hasTerm => term.isNotEmpty;

  List<Product> get items => page?.items ?? const [];

  bool get isEmpty => hasTerm && !loading && error == null && items.isEmpty;
}

final searchResultsProvider =
    NotifierProvider<SearchResultsNotifier, SearchResultsState>(
      SearchResultsNotifier.new,
    );

/// Búsqueda de 07.1 SCR-CAT-02: 300 ms de debounce y una consulta por término
/// válido. El término se recuerda en el historial local (05#D-13).
class SearchResultsNotifier extends Notifier<SearchResultsState> {
  static const debounce = Duration(milliseconds: 300);

  Timer? _debounce;
  int _requestId = 0;

  @override
  SearchResultsState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchResultsState();
  }

  void search(String rawTerm) {
    _debounce?.cancel();
    final term = rawTerm.trim();
    if (term.isEmpty) {
      _requestId++;
      state = const SearchResultsState();
      return;
    }
    _debounce = Timer(debounce, () => _run(term));
  }

  void submit(String rawTerm) {
    _debounce?.cancel();
    final term = rawTerm.trim();
    if (term.isEmpty) {
      state = const SearchResultsState();
      return;
    }
    _run(term);
  }

  Future<void> retry() async {
    if (state.term.isEmpty) {
      return;
    }
    await _run(state.term);
  }

  Future<void> _run(String term) async {
    final requestId = ++_requestId;
    state = SearchResultsState(term: term, loading: true);

    final results = await AsyncValue.guard(
      () => ref
          .read(catalogRepositoryProvider)
          .getProducts(ProductFilter(search: term)),
    );

    if (requestId != _requestId) {
      return;
    }

    state = SearchResultsState(
      term: term,
      page: results.value,
      error: results.hasError ? results.error : null,
    );

    if (results.hasValue) {
      await ref.read(searchHistoryProvider.notifier).remember(term);
    }
  }
}

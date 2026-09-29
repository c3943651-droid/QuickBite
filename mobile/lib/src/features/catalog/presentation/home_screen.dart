import 'catalog_header.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/scrollable_fill.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/domain/catalog_entities.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../notification/presentation/notification_providers.dart';
import 'catalog_providers.dart';
import 'filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String term) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (mounted) {
        ref.read(productFilterProvider.notifier).search(term.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final filter = ref.watch(productFilterProvider);
    final selectedCategory = filter.categoryId;
    final activeFilters = _activeFilterCount(filter);
    final userName = session.value?.user.nombre ?? '';
    final sinLeer = ref.watch(notificationsNoLeidasProvider);

    return Scaffold(
      // El saludo vive en la banda superior en vez de en el AppBar: el
      // degradado oscuro da el punto de anclaje de la pantalla y separa el
      // encabezado del catálogo sin una línea divisoria.
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        color: AppColors.accent,
        child: Column(
          children: [
            CatalogHeader(
              nombre: userName.isEmpty ? 'QuickBite' : userName,
              notificaciones: sinLeer,
              onNotificaciones: () => context.push('/notifications'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar en el menú',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  // 07.1 SCR-CAT-02: la búsqueda rápida filtra el catálogo; este
                  // acceso abre la pantalla dedicada con historial.
                  suffixIcon: IconButton(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.travel_explore, size: 20),
                    tooltip: 'Búsqueda avanzada',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: categories.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => const SizedBox.shrink(),
                data: (items) => _CategoryChips(
                  categories: items,
                  selectedId: selectedCategory,
                  onSelected: (id) => ref
                      .read(productFilterProvider.notifier)
                      .selectCategory(id),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openFilters(context, categories),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Filtros'),
                      if (activeFilters > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$activeFilters',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(products)),
          ],
        ),
      ),
    );
  }

  /// 07.1 SCR-CAT-03: cuenta cuántos filtros distintos hay activos para
  /// mostrarlos en el botón y no obligar a abrir la hoja.
  static int _activeFilterCount(ProductFilter filter) {
    var count = 0;
    if (filter.categoryId != null) count++;
    if (filter.precioMin != null || filter.precioMax != null) count++;
    if (!filter.disponible) count++;
    if (filter.sort != ProductSort.relevancia) count++;
    return count;
  }

  Future<void> _openFilters(
    BuildContext context,
    AsyncValue<List<Category>> categories,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FilterSheet(
        categories: categories.value ?? const <Category>[],
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody(AsyncValue<ProductPage> products) {
    return switch (products) {
      AsyncError(:final error) => ScrollableFill(
        child: ErrorStateView(
          message: error is Exception
              ? _messageFor(error)
              : 'Ocurrió un error inesperado.',
          onRetry: () => ref.read(productsProvider.notifier).refresh(),
        ),
      ),
      AsyncData(:final value) when value.items.isEmpty => const ScrollableFill(
        child: EmptyStateView(message: 'No hay productos disponibles'),
      ),
      AsyncData(:final value) => GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          // 0.72 (el valor heredado) dejaba la foto al 85% de la tarjeta y
          // prensaba nombre y precio contra el borde: en el Moto G15 la rejilla
          // se leía como una columna de huecos vacíos. 0.86 mantiene la imagen
          // como protagonista sin sacrificar el texto.
          childAspectRatio: 0.86,
        ),
        itemCount: value.items.length + (value.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= value.items.length) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final producto = value.items[index];
          return ProductCard(
            product: producto,
            onTap: () => context.push('/product/${producto.id}'),
            onQuickAdd: producto.disponible
                ? () async {
                    try {
                      await ref
                          .read(cartProvider.notifier)
                          .addItem(productoId: producto.id, cantidad: 1);
                      if (context.mounted) {
                        AppSnackbar.showSuccess(context, 'Agregado al carrito');
                      }
                    } on Exception {
                      if (context.mounted) {
                        AppSnackbar.showError(
                          context,
                          'No se pudo agregar al carrito.',
                        );
                      }
                    }
                  }
                : null,
          );
        },
      ),
      _ => const ProductGridSkeleton(),
    };
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.userMessage;
    }
    return 'No pudimos cargar el catálogo. Inténtalo de nuevo.';
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          // `CategoryChip` y no un `FilterChip` suelto: el chip del design system
          // sí sigue el tema. Con `labelStyle` fijo, la píldora inactiva quedaba
          // ciruela sobre pizarra profunda en modo oscuro (0.2:1, ilegible).
          child: CategoryChip(
            label: 'Todas',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: CategoryChip(
              label: category.nombre,
              selected: category.id == selectedId,
              onTap: () => onSelected(category.id),
            ),
          ),
      ],
    );
  }
}

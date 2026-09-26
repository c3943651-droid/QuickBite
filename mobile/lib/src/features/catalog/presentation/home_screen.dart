import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../catalog/domain/catalog_entities.dart';
import '../../auth/presentation/auth_providers.dart';
import 'catalog_providers.dart';

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
    final selectedCategory = ref.watch(productFilterProvider).categoryId;
    final userName = session.value?.user.nombre ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(userName.isEmpty ? 'QuickBite' : 'Hola, $userName'),
        actions: [
          IconButton(
            onPressed: () => AppSnackbar.showInfo(
              context,
              'Las notificaciones estarán disponibles próximamente.',
            ),
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificaciones',
            constraints: const BoxConstraints.tightFor(
              width: AppSizes.minTapTarget,
              height: AppSizes.minTapTarget,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        color: AppColors.quickbiteOrange,
        child: Column(
          children: [
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
                decoration: const InputDecoration(
                  hintText: 'Buscar en el menú',
                  prefixIcon: Icon(Icons.search, size: 20),
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
                  onPressed: () => AppSnackbar.showInfo(
                    context,
                    'Los filtros avanzados estarán disponibles próximamente.',
                  ),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Filtros'),
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

  Widget _buildBody(AsyncValue<ProductPage> products) {
    return switch (products) {
      AsyncError(:final error) => _ScrollableFill(
        child: ErrorStateView(
          message: error is Exception
              ? _messageFor(error)
              : 'Ocurrió un error inesperado.',
          onRetry: () => ref.read(productsProvider.notifier).refresh(),
        ),
      ),
      AsyncData(:final value) when value.items.isEmpty => const _ScrollableFill(
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
          childAspectRatio: 0.72,
        ),
        itemCount: value.items.length + (value.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= value.items.length) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          return ProductCard(
            product: value.items[index],
            onTap: () => AppSnackbar.showInfo(
              context,
              '${value.items[index].nombre} · ${CurrencyFormatter.format(value.items[index].precio)}',
            ),
            onQuickAdd: () => AppSnackbar.showInfo(
              context,
              'El carrito llegará en el próximo hito.',
            ),
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
          child: FilterChip(
            label: const Text('Todas'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
            selectedColor: AppColors.quickbiteOrange,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selectedId == null ? AppColors.white : AppColors.textGray,
            ),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(category.nombre),
              selected: category.id == selectedId,
              onSelected: (_) => onSelected(category.id),
              selectedColor: AppColors.quickbiteOrange,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: category.id == selectedId
                    ? AppColors.white
                    : AppColors.textGray,
              ),
            ),
          ),
      ],
    );
  }
}

class _ScrollableFill extends StatelessWidget {
  const _ScrollableFill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

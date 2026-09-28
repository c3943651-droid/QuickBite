import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/state_views.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 07.1 SCR-CAT-02: el campo arranca activo para escribir sin un toque extra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String term) {
    ref.read(searchResultsProvider.notifier).search(term);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (term) =>
                  ref.read(searchResultsProvider.notifier).submit(term),
              decoration: InputDecoration(
                hintText: 'Buscar en el menú',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: switch (state) {
              _ when !state.hasTerm => _RecentSearches(
                history: history.value?.terms ?? const <String>[],
                onSelected: (term) {
                  _controller.text = term;
                  ref.read(searchResultsProvider.notifier).submit(term);
                },
              ),
              _ when state.loading => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              _ when state.error != null => _ScrollableFill(
                child: ErrorStateView(
                  message: _messageFor(state.error!),
                  onRetry: () =>
                      ref.read(searchResultsProvider.notifier).retry(),
                ),
              ),
              _ when state.isEmpty => const _ScrollableFill(
                child: EmptyStateView(message: 'No encontramos productos'),
              ),
              _ => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final product = state.items[index];
                  return ProductCard(
                    product: product,
                    layout: ProductCardLayout.list,
                    onTap: () {},
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.userMessage;
    }
    return 'No pudimos buscar productos. Inténtalo de nuevo.';
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.history, required this.onSelected});

  final List<String> history;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return const _ScrollableFill(
        child: EmptyStateView(message: 'Busca productos del menú'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Búsquedas recientes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Borrar historial'),
            ),
          ],
        ),
        for (final term in history)
          ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(term),
            onTap: () => onSelected(term),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Quitar "$term" del historial',
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).remove(term),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          'Se eliminarán las búsquedas guardadas en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(searchHistoryProvider.notifier).clear();
    }
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

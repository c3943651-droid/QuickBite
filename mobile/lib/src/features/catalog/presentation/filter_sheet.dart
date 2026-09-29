import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chips.dart';
import '../domain/catalog_entities.dart';
import 'catalog_providers.dart';

/// Hoja modal de filtros avanzados (07.1 SCR-CAT-03). Trabaja sobre una copia
/// del filtro activo: nada cambia en el catálogo hasta pulsar "Aplicar filtros".
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({
    super.key,
    required this.categories,
    required this.onClose,
  });

  final List<Category> categories;
  final VoidCallback onClose;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late String? _categoryId;
  late bool _disponible;
  late ProductSort _sort;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  String? _rangoError;

  @override
  void initState() {
    super.initState();
    final current = ref.read(productFilterProvider);
    _categoryId = current.categoryId;
    _disponible = current.disponible;
    _sort = current.sort;
    _minController.text = current.precioMin?.toStringAsFixed(0) ?? '';
    _maxController.text = current.precioMax?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = _parse(_minController.text);
    final max = _parse(_maxController.text);
    if (min != null && max != null && min > max) {
      setState(
        () => _rangoError = 'El mínimo no puede ser mayor que el máximo',
      );
      return;
    }
    setState(() => _rangoError = null);
    ref
        .read(productFilterProvider.notifier)
        .applyAll(
          ProductFilter(
            categoryId: _categoryId,
            disponible: _disponible,
            sort: _sort,
            precioMin: min,
            precioMax: max,
          ),
        );
    widget.onClose();
  }

  void _clear() {
    setState(() {
      _categoryId = null;
      _disponible = true;
      _sort = ProductSort.relevancia;
      _minController.clear();
      _maxController.clear();
      _rangoError = null;
    });
  }

  static double? _parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar filtros',
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Categoría'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _CategoryOption(
                  label: 'Todas',
                  selected: _categoryId == null,
                  onSelected: () => setState(() => _categoryId = null),
                ),
                for (final category in widget.categories)
                  _CategoryOption(
                    label: category.nombre,
                    selected: _categoryId == category.id,
                    onSelected: () => setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionLabel('Precio'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio mínimo',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    onChanged: (_) => setState(() => _rangoError = null),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio máximo',
                      prefixIcon: Icon(Icons.price_change_outlined),
                    ),
                    onChanged: (_) => setState(() => _rangoError = null),
                  ),
                ),
              ],
            ),
            if (_rangoError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _rangoError!,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              value: _disponible,
              onChanged: (value) => setState(() => _disponible = value),
              title: const Text('Solo productos disponibles'),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _SectionLabel('Ordenar por'),
            DropdownButtonFormField<ProductSort>(
              initialValue: _sort,
              items: [
                for (final sort in ProductSort.values)
                  DropdownMenuItem(value: sort, child: Text(sort.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sort = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(0, AppSizes.buttonHeight),
              ),
              child: const Text('Aplicar filtros'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _clear,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSizes.buttonHeight),
              ),
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    // Mismo chip del design system que el resto de filtros: el `ChoiceChip` con
    // `labelStyle` fijo dejaba el texto inactivo ciruela sobre pizarra en modo
    // oscuro, y en claro compite con el fondo de la hoja.
    return CategoryChip(
      label: label,
      selected: selected,
      onTap: onSelected,
    );
  }
}

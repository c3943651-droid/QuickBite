import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/catalog/domain/catalog_entities.dart';

/// `grid` para el catálogo de dos columnas (07.1 SCR-CAT-01) y `list` para
/// los resultados de búsqueda (07.1 SCR-CAT-02).
enum ProductCardLayout { grid, list }

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQuickAdd,
    this.layout = ProductCardLayout.grid,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;
  final ProductCardLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout == ProductCardLayout.list) {
      return _ListCard(product: product, onTap: onTap, onQuickAdd: onQuickAdd);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Image(url: product.imagenUrl, nombre: product.nombre),
                  if (!product.disponible) const _AgotadoBadge(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          CurrencyFormatter.format(product.precio),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (onQuickAdd != null)
                    SizedBox(
                      width: AppSizes.minTapTarget,
                      height: AppSizes.minTapTarget,
                      child: IconButton(
                        onPressed: product.disponible ? onQuickAdd : null,
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.quickbiteOrange,
                        ),
                        tooltip: 'Agregar al carrito',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 07.1 SCR-CAT-01: un producto sin stock se anuncia como "Agotado" en lugar
/// de desaparecer del catálogo.
class _AgotadoBadge extends StatelessWidget {
  const _AgotadoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Agotado',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.product, this.onTap, this.onQuickAdd});

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: _Image(url: product.imagenUrl, nombre: product.nombre),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!product.disponible) const _AgotadoBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.format(product.precio),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onQuickAdd != null)
                IconButton(
                  onPressed: product.disponible ? onQuickAdd : null,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.quickbiteOrange,
                  ),
                  tooltip: 'Agregar al carrito',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.url, required this.nombre});

  final String? url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder(context);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => _placeholder(context),
      errorWidget: (context, _, _) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppColors.mistGray,
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          color: AppColors.secondaryGray,
          size: 32,
          semanticLabel: nombre,
        ),
      ),
    );
  }
}

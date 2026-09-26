import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/catalog/domain/catalog_entities.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQuickAdd,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Image(url: product.imagenUrl, nombre: product.nombre),
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

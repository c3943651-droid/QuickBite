import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_url.dart';
import '../../domain/cart_entities.dart';
import '../cart_providers.dart';

/// Tarjeta de un item del carrito (07.1 SCR-CART-01).
///
/// Estructura fija en tres bloques: la imagen del producto a la izquierda,
/// el nombre con los precios en el centro, y los controles de cantidad y
/// eliminar alineados a la derecha.
class CartItemCard extends ConsumerWidget {
  const CartItemCard({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final tema = Theme.of(context);
    final apiBaseUrl = ref.watch(appConfigProvider).apiBaseUrl;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(
              url: resolverUrlImagen(item.imagenUrl, apiBaseUrl: apiBaseUrl),
              nombre: item.nombre,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (item.opciones.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        item.opciones.join(' · '),
                        style: tema.textTheme.bodySmall,
                      ),
                    ),
                  if (item.observaciones != null &&
                      item.observaciones!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Nota: ${item.observaciones}',
                        style: tema.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(item.precio),
                        style: tema.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 4),
                      Text('c/u', style: tema.textTheme.labelSmall),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _QuantityStepper(
                  cantidad: item.cantidad,
                  onChanged: (value) => notifier.setQuantity(item.id, value),
                ),
                IconButton(
                  onPressed: () => notifier.removeItem(item.id),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Eliminar del carrito',
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.cantidad, required this.onChanged});

  final int cantidad;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChanged(cantidad - 1),
            icon: const Icon(Icons.remove, size: 18),
            tooltip: 'Quitar una unidad',
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              // Color explícito: el número es la cifra que el usuario lee para
              // saber cuántas unidades pidió, y sobre la tarjeta blanca se
              // perdía con el estilo heredado.
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(cantidad + 1),
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Agregar una unidad',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.nombre});

  final String? url;
  final String nombre;

  /// Marcador de posición: mismo icono y tono que la tarjeta de catálogo, para
  /// que el carrito no parezca un hueco cuando el producto no trae imagen.
  Widget _placeholder() => Icon(
    Icons.fastfood_outlined,
    color: AppColors.inkMuted,
    semanticLabel: nombre,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.image),
      ),
      child: url == null || url!.isEmpty
          ? _placeholder()
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: CachedNetworkImage(
                imageUrl: url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                // Mismo tratamiento que la tarjeta de catálogo: la imagen se
                // cachea y, si falla, cae al icono en vez de romperse.
                placeholder: (_, _) => _placeholder(),
                errorWidget: (_, _, _) => _placeholder(),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/currency_formatter.dart';
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: item.imagenUrl, nombre: item.nombre),
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
              style: Theme.of(context).textTheme.titleSmall,
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
          ? Icon(
              Icons.fastfood_outlined,
              color: AppColors.inkMuted,
              semanticLabel: nombre,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: Image.network(
                url!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.fastfood_outlined,
                  color: AppColors.inkMuted,
                  semanticLabel: nombre,
                ),
              ),
            ),
    );
  }
}

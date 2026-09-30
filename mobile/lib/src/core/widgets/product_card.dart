import '../theme/app_radius.dart';

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
    return _TarjetaCatalogo(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Image(
                    url: product.imagenUrl,
                    nombre: product.nombre,
                    hero: heroProducto(product.id),
                  ),
                  if (product.esPopular) const _PopularBadge(),
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
                        SizedBox(
                          height: _altoNombre(
                            Theme.of(context).textTheme.titleMedium,
                          ),
                          child: Text(
                            product.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (product.calificacion != null ||
                            product.tiempoEstimado != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (product.calificacion != null) ...[
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.calificacion}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                              if (product.calificacion != null &&
                                  product.tiempoEstimado != null)
                                const SizedBox(width: 8),
                              if (product.tiempoEstimado != null)
                                Text(
                                  product.tiempoEstimado!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          CurrencyFormatter.format(product.precio),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D9488),
                          ),
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
                          color: AppColors.accent,
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

/// Alto que ocupa el nombre de la tarjeta, ocupe una línea o dos.
///
/// El nombre va en `maxLines: 2`. Sin reservar ese alto, el bloque de texto
/// crece con la segunda línea y la imagen `Expanded` cede ese espacio: las
/// fotos de dos tarjetas de la misma fila quedan a distinta altura y el
/// catálogo se ve descuadrado. Se reserva a partir del tema, no con un número
/// fijo, para que un cambio de tipografía no lo desalinee otra vez.
double _altoNombre(TextStyle? estilo) {
  final tamano = estilo?.fontSize ?? 16;
  final altoLinea = tamano * (estilo?.height ?? 1.2);
  return altoLinea * 2;
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Popular',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
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
        color: AppColors.inkMuted,
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

/// Envoltura de tarjeta del catálogo.
///
/// 09 §7.3 sitúa las tarjetas de producto en el nivel de elevación 1 y §7.2 las
/// redondea a 16 px. Aplicar el mismo envoltorio a la rejilla y a la lista es lo
/// que hace que los dos layouts se vean como la misma tarjeta, y no como dos
/// componentes distintos que casualmente llevan el nombre.
///
/// La sombra es difusa (`BoxShadow` con `spreadRadius` negativo) en vez de la
/// elevación dura de Material: en pantalla la de Material se ve como un marco
/// gris alrededor de la tarjeta, que es justo lo que el rediseño elimina.
class _TarjetaCatalogo extends StatelessWidget {
  const _TarjetaCatalogo({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
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
    return _TarjetaCatalogo(
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
                  icon: const Icon(Icons.add_circle, color: AppColors.accent),
                  tooltip: 'Agregar al carrito',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta del Hero de un producto.
///
/// Se comparte entre la tarjeta y la pantalla de detalle: si cambia uno de los
/// dos lados, la animación deja de reconocerse y se ve un salto.
String heroProducto(String id) => 'producto-$id';

class _Image extends StatelessWidget {
  const _Image({required this.url, required this.nombre, this.hero});

  final String? url;
  final String nombre;

  /// Etiqueta del Hero. Cuando viene, la imagen "viaja" al detalle en vez de
  /// desaparecer y aparecer otra; cuando es nula (por ejemplo en un carrito)
  /// no hay nada a lo que viajar.
  final Object? hero;

  @override
  Widget build(BuildContext context) {
    final imagen = url == null || url!.isEmpty
        ? _placeholder(context)
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, _) => _placeholder(context),
            errorWidget: (context, _, _) => _placeholder(context),
          );

    final tag = hero;
    if (tag == null) return imagen;
    return Hero(tag: tag, child: imagen);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          color: AppColors.inkMuted,
          size: 32,
          semanticLabel: nombre,
        ),
      ),
    );
  }
}

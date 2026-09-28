import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/presentation/cart_providers.dart';
import '../domain/catalog_entities.dart';
import '../domain/catalog_repository.dart';
import 'catalog_providers.dart';

/// 07.1 SCR-CAT-04 — ver el detalle y personalizar un producto.
///
/// La personalización (opciones, notas y cantidad) es estado efímero de la
/// pantalla: al salir se pierde a propósito, porque el carrito es la fuente de
/// verdad y se arma al agregar.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productoId});

  final String productoId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _notas = TextEditingController();
  final Set<String> _opcionesElegidas = {};
  int _cantidad = 1;
  bool _agregando = false;

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final producto = ref.watch(productProvider(widget.productoId));
    final opciones = ref.watch(productOptionsProvider(widget.productoId));

    return Scaffold(
      body: switch (producto) {
        AsyncError(:final error) => _DetalleError(
          mensaje: error is AppException
              ? error.userMessage
              : 'No pudimos cargar el producto.',
          onRetry: () => ref.invalidate(productProvider(widget.productoId)),
        ),
        AsyncData(:final value) => _DetalleBody(
          producto: value,
          opciones: opciones.value ?? const [],
          opcionesCargando: opciones.isLoading,
          notas: _notas,
          cantidad: _cantidad,
          opcionesElegidas: _opcionesElegidas,
          onToggleOpcion: _toggleOpcion,
          onCantidadChanged: _cambiarCantidad,
        ),
        _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      },
      bottomNavigationBar: switch (producto) {
        AsyncData(:final value) => _BarraAgregar(
          producto: value,
          opciones: opciones.value ?? const [],
          cantidad: _cantidad,
          opcionesElegidas: _opcionesElegidas,
          agregando: _agregando,
          onAgregar: () => _agregar(value),
        ),
        _ => null,
      },
    );
  }

  void _toggleOpcion(String id) {
    if (!_productoDisponible) {
      return;
    }
    setState(() {
      if (!_opcionesElegidas.remove(id)) {
        _opcionesElegidas.add(id);
      }
    });
  }

  bool get _productoDisponible =>
      ref.read(productProvider(widget.productoId)).value?.disponible ?? false;

  void _cambiarCantidad(int delta) {
    if (!_productoDisponible) {
      return;
    }
    setState(() {
      _cantidad = (_cantidad + delta).clamp(1, 99);
    });
  }

  Future<void> _agregar(Product producto) async {
    if (!producto.disponible || _agregando) {
      return;
    }
    setState(() => _agregando = true);
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(
            productoId: producto.id,
            cantidad: _cantidad,
            observaciones: _notas.text.trim().isEmpty
                ? null
                : _notas.text.trim(),
            opcionIds: _opcionesElegidas.toList(),
          );
      if (!mounted) {
        return;
      }
      AppSnackbar.showSuccess(context, 'Agregado al carrito');
    } on AppException catch (error) {
      if (mounted) {
        AppSnackbar.showError(context, error.userMessage);
      }
    } on Exception {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'No se pudo agregar al carrito. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _agregando = false);
      }
    }
  }
}

class _DetalleError extends StatelessWidget {
  const _DetalleError({required this.mensaje, required this.onRetry});

  final String mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorStateView(
      message: mensaje,
      onRetry: onRetry,
      actionLabel: 'Ir al catálogo',
      onAction: () => context.go('/home'),
    );
  }
}

class _DetalleBody extends StatelessWidget {
  const _DetalleBody({
    required this.producto,
    required this.opciones,
    required this.opcionesCargando,
    required this.notas,
    required this.cantidad,
    required this.opcionesElegidas,
    required this.onToggleOpcion,
    required this.onCantidadChanged,
  });

  final Product producto;
  final List<ProductOption> opciones;
  final bool opcionesCargando;
  final TextEditingController notas;
  final int cantidad;
  final Set<String> opcionesElegidas;
  final ValueChanged<String> onToggleOpcion;
  final ValueChanged<int> onCantidadChanged;

  @override
  Widget build(BuildContext context) {
    final extraOpciones = _extraOpciones();

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        _ImagenProducto(url: producto.imagenUrl, nombre: producto.nombre),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                CurrencyFormatter.format(producto.precio),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.quickbiteOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  StatusChip(
                    label: producto.disponible ? 'Disponible' : 'Agotado',
                    tone: producto.disponible
                        ? StatusTone.success
                        : StatusTone.danger,
                    icon: producto.disponible
                        ? Icons.check_circle_outline
                        : Icons.remove_shopping_cart_outlined,
                  ),
                  if (producto.categoria != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      producto.categoria!.nombre,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (producto.descripcion case final descripcion?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  descripcion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Personaliza tu pedido',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (opcionesCargando)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (opciones.isEmpty)
                Text(
                  'Este producto no tiene opciones configurables.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...opciones.map(
                  (opcion) => CheckboxListTile(
                    value: opcionesElegidas.contains(opcion.id),
                    onChanged: producto.disponible
                        ? (_) => onToggleOpcion(opcion.id)
                        : null,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(opcion.nombre),
                    secondary: Text(
                      opcion.precioAdicional == 0
                          ? 'Incluido'
                          : '+${CurrencyFormatter.format(opcion.precioAdicional)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notas,
                enabled: producto.disponible,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  hintText: 'Sin cebolla, extra salsa…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ajustar cantidad',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  _SelectorCantidad(
                    cantidad: cantidad,
                    onChanged: producto.disponible ? onCantidadChanged : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ResumenPrecio(
                precioUnitario: producto.precio,
                extraOpciones: extraOpciones,
                cantidad: cantidad,
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _extraOpciones() {
    return opciones
        .where((opcion) => opcionesElegidas.contains(opcion.id))
        .fold(0, (suma, opcion) => suma + opcion.precioAdicional);
  }
}

class _ResumenPrecio extends StatelessWidget {
  const _ResumenPrecio({
    required this.precioUnitario,
    required this.extraOpciones,
    required this.cantidad,
  });

  final double precioUnitario;
  final double extraOpciones;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final unitario = precioUnitario + extraOpciones;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mistGray.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          _FilaResumen(
            'Precio unitario',
            CurrencyFormatter.format(precioUnitario),
          ),
          _FilaResumen('Opciones', CurrencyFormatter.format(extraOpciones)),
          _FilaResumen(
            'Cantidad',
            '$cantidad × ${CurrencyFormatter.format(unitario)}',
          ),
          const Divider(height: AppSpacing.lg),
          _FilaResumen(
            'Total',
            CurrencyFormatter.format(unitario * cantidad),
            esTotal: true,
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.label, this.valor, {this.esTotal = false});

  final String label;
  final String valor;
  final bool esTotal;

  @override
  Widget build(BuildContext context) {
    final style = esTotal
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(valor, style: style),
        ],
      ),
    );
  }
}

class _SelectorCantidad extends StatelessWidget {
  const _SelectorCantidad({required this.cantidad, required this.onChanged});

  final int cantidad;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mistGray),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onChanged == null ? null : () => onChanged!(-1),
            icon: const Icon(Icons.remove, size: 18),
            tooltip: 'Quitar una unidad',
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            onPressed: onChanged == null ? null : () => onChanged!(1),
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Agregar una unidad',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _BarraAgregar extends StatelessWidget {
  const _BarraAgregar({
    required this.producto,
    required this.opciones,
    required this.cantidad,
    required this.opcionesElegidas,
    required this.agregando,
    required this.onAgregar,
  });

  final Product producto;
  final List<ProductOption> opciones;
  final int cantidad;
  final Set<String> opcionesElegidas;
  final bool agregando;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final extraOpciones = opciones
        .where((opcion) => opcionesElegidas.contains(opcion.id))
        .fold<double>(0, (suma, opcion) => suma + opcion.precioAdicional);
    final total = (producto.precio + extraOpciones) * cantidad;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.mistGray)),
        ),
        child: PrimaryButton(
          label: producto.disponible
              ? 'Agregar al carrito - ${CurrencyFormatter.format(total)}'
              : 'No disponible',
          isLoading: agregando,
          onPressed: producto.disponible ? onAgregar : null,
        ),
      ),
    );
  }
}

class _ImagenProducto extends StatelessWidget {
  const _ImagenProducto({required this.url, required this.nombre});

  final String? url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.mistGray,
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Icon(
          Icons.fastfood_outlined,
          size: 64,
          color: AppColors.secondaryGray,
          semanticLabel: nombre,
        ),
      ),
    );

    return Stack(
      children: [
        if (url == null || url!.isEmpty)
          placeholder
        else
          Image.network(
            url!,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: Material(
            color: AppColors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
          ),
        ),
      ],
    );
  }
}

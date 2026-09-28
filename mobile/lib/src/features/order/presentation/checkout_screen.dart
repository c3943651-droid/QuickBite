import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../address/domain/address_entities.dart';
import '../../address/presentation/address_providers.dart';
import '../../cart/domain/cart_entities.dart';
import '../../cart/presentation/cart_providers.dart';
import '../domain/order_entities.dart';
import 'checkout_providers.dart';

/// 07.1 SCR-CART-02 — Confirmar el pedido con dirección y método de pago.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: SafeArea(
        child: switch (cart) {
          AsyncError(:final error) => ErrorStateView(
            message: error is AppException
                ? error.userMessage
                : 'No pudimos cargar tu carrito.',
            onRetry: () => ref.read(cartProvider.notifier).refresh(),
          ),
          AsyncData(:final value) when value.isEmpty => EmptyStateView(
            message: 'Tu carrito está vacío',
            icon: Icons.shopping_cart_outlined,
            actionLabel: 'Volver al carrito',
            onAction: () => context.go('/cart'),
          ),
          AsyncData(:final value) => _CheckoutBody(cart: value),
          _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        },
      ),
      bottomNavigationBar: switch (cart) {
        AsyncData(:final value) when !value.isEmpty => _ConfirmBar(cart: value),
        _ => null,
      },
    );
  }
}

class _CheckoutBody extends ConsumerWidget {
  const _CheckoutBody({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final direcciones = ref.watch(addressesProvider);
    final direccion = ref.watch(checkoutDireccionProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Dirección de entrega'),
        const SizedBox(height: AppSpacing.sm),
        switch (direcciones) {
          AsyncData(:final value) when value.isEmpty =>
            PrimaryButton(
              label: 'Agregar nueva dirección',
              icon: Icons.add_location_alt_outlined,
              onPressed: () => context.push('/addresses/new'),
            ),
          AsyncData(:final value) => _AddressList(
            direcciones: value,
            seleccionadaId: direccion?.id,
            onSelected: (id) =>
                ref.read(checkoutProvider.notifier).seleccionarDireccion(id),
          ),
          AsyncError() => ErrorStateView(
            message: 'No pudimos cargar tus direcciones.',
            onRetry: () => ref.invalidate(addressesProvider),
          ),
          _ => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        },
        if (direccion != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/addresses/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar nueva dirección'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Método de pago'),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<MetodoPago>(
          groupValue: checkout.metodoPago,
          onChanged: (value) {
            if (value != null) {
              ref.read(checkoutProvider.notifier).seleccionarMetodoPago(value);
            }
          },
          child: Column(
            children: [
              for (final metodo in MetodoPago.values)
                RadioListTile<MetodoPago>(
                  value: metodo,
                  title: Text(metodo.etiqueta),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Observaciones generales'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ej. tocar el timbre, sin cebolla',
            border: OutlineInputBorder(),
          ),
          onChanged: ref.read(checkoutProvider.notifier).setNotas,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle('Resumen del pedido'),
        const SizedBox(height: AppSpacing.sm),
        for (final item in cart.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('${item.cantidad} × ${item.nombre}'),
            trailing: Text(CurrencyFormatter.format(item.subtotal)),
          ),
        const Divider(),
        _TotalRow(label: 'Subtotal', value: cart.subtotal),
        _TotalRow(label: 'Costo de envío', value: cart.costoEnvio),
        _TotalRow(label: 'Total', value: cart.total, destacado: true),
        if (checkout.error case final error?) ...[
          const SizedBox(height: AppSpacing.md),
          _ErrorBanner(message: error),
        ],
      ],
    );
  }
}

class _ConfirmBar extends ConsumerWidget {
  const _ConfirmBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enviando = ref.watch(checkoutProvider.select((state) => state.enviando));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: PrimaryButton(
          label: 'Confirmar pedido - ${CurrencyFormatter.format(cart.total)}',
          isLoading: enviando,
          onPressed: enviando ? null : () => _confirmar(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmar(BuildContext context, WidgetRef ref) async {
    final checkout = ref.read(checkoutProvider.notifier);
    final pedido = await checkout.confirmar();
    if (!context.mounted) return;
    if (pedido != null) {
      context.push('/order/confirmation/${pedido.id}');
      return;
    }
    final error = ref.read(checkoutProvider).error;
    if (error != null) {
      AppSnackbar.showError(context, error);
    }
  }
}

class _AddressList extends StatelessWidget {
  const _AddressList({
    required this.direcciones,
    required this.seleccionadaId,
    required this.onSelected,
  });

  final List<Address> direcciones;
  final String? seleccionadaId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: seleccionadaId,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      child: Column(
        children: [
          for (final direccion in direcciones)
            RadioListTile<String>(
              value: direccion.id,
              contentPadding: EdgeInsets.zero,
              title: Text(_etiqueta(direccion)),
              subtitle: direccion.alias == null ? null : Text(direccion.alias!),
            ),
        ],
      ),
    );
  }

  static String _etiqueta(Address direccion) {
    return [
      [direccion.calle, direccion.numero]
          .where((valor) => valor != null && valor.isNotEmpty)
          .join(' '),
      direccion.ciudad,
    ].where((parte) => parte.isNotEmpty).join(', ');
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.destacado = false,
  });

  final String label;
  final double value;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final style = destacado
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.format(value), style: style),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

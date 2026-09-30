import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/pedido_entrega.dart';
import 'delivery_providers.dart';

/// Detalle de un pedido disponible antes de tomarlo (07.1 SCR-DEL-02).
///
/// La lista trae el mismo `OrderResponse` que el detalle, así que la pantalla
/// busca el pedido en la lista ya cargada en vez de pedirlo otra vez: así el
/// repartidor ve exactamente lo mismo que vio al tocar la tarjeta.
class AvailableOrderDetailScreen extends ConsumerWidget {
  const AvailableOrderDetailScreen({super.key, required this.pedidoId});

  final String pedidoId;

  static const destinoAceptado = '/delivery/active';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidos = ref.watch(pedidosDisponiblesProvider).pedidos;
    final coincidencias = pedidos.where((p) => p.id == pedidoId);

    if (coincidencias.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Este pedido ya no está disponible',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pedido = coincidencias.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedido disponible')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  pedido.numeroPedido,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Dirección, productos y observaciones no llegan todavía:
                // `GET /delivery/available` solo manda número, estado, total y
                // fecha (04 §11.1). Los bloques aparecen sin cambios cuando el
                // endpoint los exponga.
                _Fila(
                  icon: Icons.payments_outlined,
                  titulo: 'Total',
                  valor: CurrencyFormatter.format(pedido.total),
                ),
                if (pedido.minutosDesdeCreacion(DateTime.now())
                    case final m?) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Fila(
                    icon: Icons.schedule,
                    titulo: 'Esperando',
                    valor: '$m min',
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryButton(
                label: 'Aceptar entrega',
                isLoading: ref.watch(pedidosDisponiblesProvider).aceptando,
                onPressed: pedido.sePuedeAceptar
                    ? () => _aceptar(context, ref, pedido)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _aceptar(
    BuildContext context,
    WidgetRef ref,
    PedidoEntrega pedido,
  ) async {
    final notifier = ref.read(pedidosDisponiblesProvider.notifier);
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Aceptar este pedido?',
      message:
          'Pedido ${pedido.numeroPedido} por ${CurrencyFormatter.format(pedido.total)}.',
      confirmLabel: 'Aceptar',
    );
    if (!confirmado || !context.mounted) return;

    final ok = await notifier.aceptar(pedido.id);
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(
        context,
        'Pedido ${pedido.numeroPedido} asignado',
      );
      context.go(destinoAceptado);
      return;
    }
    final error = ref.read(pedidosDisponiblesProvider).accionError;
    notifier.limpiarAccionError();
    AppSnackbar.showError(context, error ?? 'No se pudo aceptar el pedido');
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icon, required this.titulo, required this.valor});

  final IconData icon;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.labelMedium),
              Text(valor, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

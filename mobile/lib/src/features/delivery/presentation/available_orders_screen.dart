import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/polling/polling_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/polling_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/pedido_entrega.dart';
import 'active_delivery_screen.dart';
import 'delivery_providers.dart';

/// Pedidos listos para tomar (07.1 SCR-DEL-01).
///
/// La lista se refresca sola cada 30 s porque el pedido se lo lleva quien
/// pulse antes: sin eso, el repartidor ve una lista que ya caducó y toca
/// "Aceptar" sobre un pedido que otro took.
class AvailableOrdersScreen extends ConsumerStatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  ConsumerState<AvailableOrdersScreen> createState() =>
      _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends ConsumerState<AvailableOrdersScreen>
    with WidgetsBindingObserver {
  /// `ref` no vale en [dispose], así que el motor se guarda al entrar.
  late PollingController _polling;

  @override
  void initState() {
    super.initState();
    _polling = ref.read(pedidosDisponiblesProvider.notifier).polling;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 07 §8.6: al salir de la pantalla el polling se detiene, para no seguir
    // consultando la API detrás de una pantalla que nadie mira.
    _polling.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 07 §8.6: se pausa en segundo plano y se reanuda al volver.
    ref
        .read(pedidosDisponiblesProvider.notifier)
        .setVisible(state == AppLifecycleState.resumed);
  }

  Future<void> _aceptar(PedidoEntrega pedido) async {
    final notifier = ref.read(pedidosDisponiblesProvider.notifier);
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Aceptar este pedido?',
      message:
          'Pedido ${pedido.numeroPedido} por ${CurrencyFormatter.format(pedido.total)}.',
      confirmLabel: 'Aceptar',
    );
    if (!confirmado || !mounted) return;

    final ok = await notifier.aceptar(pedido.id);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(
        context,
        'Pedido ${pedido.numeroPedido} asignado',
      );
      return;
    }
    final error = ref.read(pedidosDisponiblesProvider).accionError;
    notifier.limpiarAccionError();
    AppSnackbar.showError(context, error ?? 'No se pudo aceptar el pedido');
  }

  @override
  Widget build(BuildContext context) {
    // El repartidor tiene que cambiar de estado en cuanto le asignan un pedido,
    // sin que él tenga que refrescar. `invalidate` sobre un provider autoDispose
    // sin escuchas no consulta nada: lo que dispara la petición es que esta
    // pantalla lo escuche. Con esta escucha, el tick del polling (o el
    // `aceptar`) revalidan la entrega y, si aparece, se navega a ella
    // (07.1 SCR-DEL-03).
    ref.listen<AsyncValue<PedidoEntrega?>>(entregaActivaProvider, (
      anterior,
      actual,
    ) {
      final pedido = actual.value;
      if (pedido != null && mounted) {
        context.go(ActiveDeliveryScreen.destinoConEntrega);
      }
    });
    final state = ref.watch(pedidosDisponiblesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos disponibles'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(pedidosDisponiblesProvider.notifier).refrescar(),
          ),
        ],
      ),
      body: Column(
        children: [
          PollingIndicator(active: state.mostrarIndicador),
          if (state.pausadoPorErrores)
            _AvisoPausa(
              onReintentar: () =>
                  ref.read(pedidosDisponiblesProvider.notifier).reintentar(),
            ),
          Expanded(
            child: _Cuerpo(state: state, onAceptar: _aceptar),
          ),
        ],
      ),
    );
  }
}

class _Cuerpo extends ConsumerWidget {
  const _Cuerpo({required this.state, required this.onAceptar});

  final PedidosDisponiblesState state;
  final Future<void> Function(PedidoEntrega) onAceptar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.cargando && state.pedidos.isEmpty) {
      return const _ListaSkeleton();
    }
    if (state.error != null && state.pedidos.isEmpty) {
      return ErrorStateView(
        message: state.error!,
        onRetry: () =>
            ref.read(pedidosDisponiblesProvider.notifier).reintentar(),
      );
    }
    if (state.vacio) {
      return const EmptyStateView(
        message: 'No hay pedidos disponibles',
        icon: Icons.inbox_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.pedidos.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final pedido = state.pedidos[index];
        return _TarjetaPedido(
          pedido: pedido,
          aceptando: state.aceptando,
          onAceptar: () => onAceptar(pedido),
        );
      },
    );
  }
}

/// Tarjeta de un pedido disponible (07.1 SCR-DEL-01).
///
/// La dirección resumida que pide la especificación no aparece porque
/// `GET /delivery/available` solo manda número, estado, total y fecha; el campo
/// aparece en cuanto el endpoint lo exponga, sin tocar esta tarjeta.
class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({
    required this.pedido,
    required this.aceptando,
    required this.onAceptar,
  });

  final PedidoEntrega pedido;
  final bool aceptando;
  final VoidCallback onAceptar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutos = pedido.minutosDesdeCreacion(DateTime.now());

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pedido.numeroPedido,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (minutos != null)
                  Text(
                    '$minutos min',
                    // El color sale del tema para que en modo oscuro no quede
                    // tinta negra sobre fondo oscuro.
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: minutos >= 20
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              CurrencyFormatter.format(pedido.total),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Aceptar entrega',
              isLoading: aceptando,
              onPressed: pedido.sePuedeAceptar ? onAceptar : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de que el polling se detuvo por errores (07 §8.6).
class _AvisoPausa extends StatelessWidget {
  const _AvisoPausa({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sin conexión. Revisa tu red para ver nuevos pedidos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ListaSkeleton extends StatelessWidget {
  const _ListaSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const _CardSkeleton(),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }
}

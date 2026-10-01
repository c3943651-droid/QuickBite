import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/location_urls.dart';
import '../../../core/external/enlaces_externos.dart';
import '../../../core/polling/polling_controller.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/polling_indicator.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_timeline.dart';
import '../../delivery/presentation/widgets/delivery_map.dart';
import '../domain/order_entities.dart';

import 'package:latlong2/latlong.dart';

import 'estado_pedido_ui.dart';
import 'order_tracking_providers.dart';

/// Seguimiento de un pedido (07.1 SCR-ORDER-01) y su detalle histórico
/// (SCR-ORDER-04): la misma pantalla sirve para ambos porque la diferencia es el
/// estado, y el estado decide el polling, el timeline y si se puede cancelar.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with WidgetsBindingObserver {
  /// `ref` no es válido en [dispose], así que se guarda el notifier para las
  /// llamadas en vida y el controlador para detener el timer al salir.
  late OrderTrackingNotifier _notifier;
  late PollingController _polling;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(orderTrackingProvider(widget.orderId).notifier);
    _polling = _notifier.polling;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 07 §8.6: el polling se detiene al salir de la pantalla.
    _polling.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _notifier.setVisible(state == AppLifecycleState.resumed);
  }

  Future<void> _cancelar(EstadoPedido estado) async {
    final motivo = await _PedidoHojaCancelacion.mostrar(context);
    if (motivo == null || !mounted) return;
    final ok = await _notifier.cancelar(motivo.isEmpty ? null : motivo);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(context, 'Tu pedido se canceló');
      return;
    }
    final error = ref.read(orderTrackingProvider(widget.orderId)).error;
    _notifier.limpiarError();
    AppSnackbar.showError(context, error ?? 'No se pudo cancelar el pedido');
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(orderTrackingProvider(widget.orderId));
    final pedido = tracking.pedido;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu pedido'),
        actions: [
          if (pedido != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(child: _EstadoChip(estado: tracking.estado)),
            ),
        ],
      ),
      body: _Body(
        tracking: tracking,
        orderId: widget.orderId,
        onCancelar: tracking.puedeCancelar
            ? () => _cancelar(tracking.estado)
            : null,
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.tracking, required this.orderId, this.onCancelar});

  final OrderTrackingState tracking;
  final String orderId;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedido = tracking.pedido;

    if (pedido == null) {
      if (tracking.cargando) return const _DetalleSkeleton();
      return ErrorStateView(
        message: tracking.error ?? 'No pudimos cargar este pedido.',
        onRetry: () =>
            ref.read(orderTrackingProvider(orderId).notifier).recargar(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        PollingIndicator(active: tracking.mostrarIndicador),
        if (tracking.pausadoPorErrores) ...[
          _Aviso(
            texto: tracking.error ?? 'Actualización pausada.',
            onReintentar: () =>
                ref.read(orderTrackingProvider(orderId).notifier).reintentar(),
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (tracking.error != null) ...[
          _Aviso(texto: tracking.error!, clave: 'aviso-inline'),
          const SizedBox(height: AppSpacing.md),
        ],

        // Mapa solo si va en camino y el pedido tiene coordenadas reales
        if (tracking.estado == EstadoPedido.enCamino &&
            pedido.latitud != null &&
            pedido.longitud != null) ...[
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: DeliveryMap(
                origin: const LatLng(13.6929, -89.2182), // QuickBite Centro
                destination: LatLng(pedido.latitud!, pedido.longitud!),
                routePolyline: const [],
                originTitle: 'QuickBite',
                destinationTitle: 'Tu ubicación',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        _Encabezado(pedido: pedido, estado: tracking.estado),
        const SizedBox(height: AppSpacing.lg),
        _Seccion(
          titulo: 'Estado del pedido',
          child: _Timeline(
            estado: tracking.estado,
            actualizadoEn: tracking.actualizadoEn,
          ),
        ),
        if (pedido.direccionEntrega.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Seccion(
            titulo: 'Entrega en',
            child: _Dato(
              icon: Icons.place_outlined,
              texto: pedido.direccionEntrega,
            ),
          ),
        ],
        if (pedido.latitud != null && pedido.longitud != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _Seccion(
            titulo: 'Abrir ubicación',
            child: _BotonesApertura(
              latitud: pedido.latitud!,
              longitud: pedido.longitud!,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Seccion(
          titulo: 'Tu pedido (${pedido.cantidadItems})',
          child: _Items(pedido: pedido),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Seccion(
          titulo: 'Totales',
          child: _Totales(pedido: pedido),
        ),
        if (onCancelar != null) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: onCancelar,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancelar pedido'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.pedido, required this.estado});

  final Order pedido;
  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pedido.numeroPedido,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          switch (estado) {
            EstadoPedido.pendiente =>
              'Recibimos tu pedido, esperando confirmación.',
            EstadoPedido.confirmado => 'Tu pedido fue confirmado.',
            EstadoPedido.preparando => 'Estamos preparando tu pedido.',
            EstadoPedido.listo => 'Tu pedido está listo para salir.',
            EstadoPedido.enCamino => 'Tu pedido va en camino.',
            EstadoPedido.entregado => 'Tu pedido fue entregado.',
            EstadoPedido.cancelado => 'Este pedido fue cancelado.',
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: estado.etiqueta, tone: estado.tone, icon: estado.icono);
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.estado, this.actualizadoEn});

  final EstadoPedido estado;
  final DateTime? actualizadoEn;

  @override
  Widget build(BuildContext context) {
    return StatusTimeline(
      steps: pasosTimeline(estado, actualizadoEn: actualizadoEn),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.pedido});

  final Order pedido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (pedido.items.isEmpty) {
      return Text(
        'Sin artículos',
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      );
    }
    return Column(
      children: [
        for (final item in pedido.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.cantidad} × ${item.nombre}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Totales extends StatelessWidget {
  const _Totales({required this.pedido});

  final Order pedido;

  @override
  Widget build(BuildContext context) {
    final subtotal = pedido.subtotal ?? pedido.total;
    return Column(
      children: [
        _Fila(etiqueta: 'Subtotal', valor: CurrencyFormatter.format(subtotal)),
        const SizedBox(height: AppSpacing.xs),
        _Fila(
          etiqueta: 'Envío',
          valor: CurrencyFormatter.format(pedido.costoEnvio ?? 0),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Fila(
          etiqueta: 'Total',
          valor: CurrencyFormatter.format(pedido.total),
          destacado: true,
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = destacado
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: style),
        Text(valor, style: style),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(texto, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Abre la ubicación de entrega en una app externa de navegación (07.5 §5).
class _BotonesApertura extends ConsumerWidget {
  const _BotonesApertura({required this.latitud, required this.longitud});

  final double latitud;
  final double longitud;

  Future<void> _abrir(BuildContext context, WidgetRef ref, Uri uri) async {
    final ok = await ref.read(externalLauncherProvider).abrir(uri);
    if (!ok && context.mounted) {
      AppSnackbar.showError(context, 'No se pudo abrir la aplicación.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _abrir(context, ref, googleMapsUri(latitud, longitud)),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Google Maps'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _abrir(context, ref, wazeUri(latitud, longitud)),
            icon: const Icon(Icons.directions_car_outlined, size: 18),
            label: const Text('Waze'),
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.onReintentar, this.clave});

  final String texto;
  final VoidCallback? onReintentar;
  final String? clave;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: clave == null ? null : ValueKey(clave!),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (onReintentar != null)
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}

class _DetalleSkeleton extends StatelessWidget {
  const _DetalleSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final alto in <double>[24, 96, 180, 120, 72])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              height: alto,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
            ),
          ),
      ],
    );
  }
}

/// Hoja modal de cancelación (07.1 SCR-ORDER-02). El motivo es opcional: si se
/// confirma sin escribir nada, la API recibe la cadena vacía.
class _PedidoHojaCancelacion extends StatefulWidget {
  const _PedidoHojaCancelacion();

  static Future<String?> mostrar(BuildContext context) => AppBottomSheet.show(
    context,
    title: '¿Cancelar pedido?',
    child: const _PedidoHojaCancelacion(),
  );

  @override
  State<_PedidoHojaCancelacion> createState() => _PedidoHojaCancelacionState();
}

class _PedidoHojaCancelacionState extends State<_PedidoHojaCancelacion> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Al cancelar recuperamos los productos y restauramos el stock. '
            'Esta acción no se puede deshacer.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(controller: _controller, label: 'Motivo (opcional)'),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Sí, cancelar pedido',
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

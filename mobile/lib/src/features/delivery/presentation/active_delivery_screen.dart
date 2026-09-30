import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/models/location_permission_status.dart';
import '../domain/pedido_entrega.dart';
import 'delivery_providers.dart';
import 'widgets/delivery_map.dart';

/// Entrega en curso (07.1 SCR-DEL-03).
///
/// Si no hay entrega, la pantalla devuelve al repartidor a la lista en vez de
/// mostrar un estado vacío: no tener nada que entregar es el caso normal, no un
/// error, y la lista es donde puede aceptar el siguiente pedido.
class ActiveDeliveryScreen extends ConsumerWidget {
  const ActiveDeliveryScreen({super.key});

  /// A dónde va el repartidor cuando ya no hay nada en curso.
  static const destinoSinEntrega = '/delivery/available';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entrega = ref.watch(entregaActivaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrega activa')),
      body: entrega.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: mensaje(error),
          onRetry: () => ref.invalidate(entregaActivaProvider),
        ),
        data: (pedido) {
          if (pedido == null) {
            return const _Redirigir();
          }
          return _Contenido(pedido: pedido);
        },
      ),
    );
  }
}

/// Envía a la lista de disponibles desde el propio árbol, para que la redirección
/// ocurra también si la pantalla se monta sin pasar por un toque.
class _Redirigir extends StatefulWidget {
  const _Redirigir();

  @override
  State<_Redirigir> createState() => _RedirigirState();
}

class _RedirigirState extends State<_Redirigir> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tras el primer frame: si se navega durante el build, go_router lanza.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(ActiveDeliveryScreen.destinoSinEntrega);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Contenido extends ConsumerStatefulWidget {
  const _Contenido({required this.pedido});

  final PedidoEntrega pedido;

  @override
  ConsumerState<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends ConsumerState<_Contenido> {
  Future<void> _completar() async {
    final notifier = ref.read(entregaAccionesProvider.notifier);
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Marcar como entregado?',
      message:
          'Pedido ${widget.pedido.numeroPedido} por '
          '${CurrencyFormatter.format(widget.pedido.total)}.',
      confirmLabel: 'Marcar como entregado',
    );
    if (!confirmado || !mounted) return;

    final ok = await notifier.completar(widget.pedido.id);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(context, 'Entrega completada');
      context.go(ActiveDeliveryScreen.destinoSinEntrega);
      return;
    }
    final error = ref.read(entregaAccionesProvider).error;
    notifier.limpiarError();
    AppSnackbar.showError(context, error ?? 'No se pudo completar la entrega');
  }

  @override
  Widget build(BuildContext context) {
    final acciones = ref.watch(entregaAccionesProvider);
    final permisos = ref.watch(locationPermissionProvider);
    final tema = Theme.of(context);
    final minutos = widget.pedido.minutosDesdeCreacion(DateTime.now());

    return Column(
      children: [
        // Mitad superior: Mapa
        Expanded(
          flex: 4,
          child: permisos.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(mensaje(e))),
            data: (status) {
              if (status == LocationPermissionStatus.whenInUse ||
                  status == LocationPermissionStatus.always) {
                // TODO: Usar coordenadas reales de la API cuando GET /delivery las exponga (04 §11.1)
                return const DeliveryMap(
                  origin: LatLng(13.6929, -89.2182), // QuickBite Centro
                  destination: LatLng(13.7000, -89.2100), // Cliente
                  routePolyline: [
                    LatLng(13.6929, -89.2182),
                    LatLng(13.6950, -89.2150),
                    LatLng(13.7000, -89.2100),
                  ],
                  originTitle: 'QuickBite',
                  destinationTitle: 'Cliente',
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off,
                          size: 48, color: AppColors.neutral500),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Necesitamos tu ubicación para mostrar la ruta.',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: 'Dar permiso',
                        onPressed: () {
                          ref
                              .read(locationPermissionProvider.notifier)
                              .requestPermission();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Mitad inferior: Detalles
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                widget.pedido.numeroPedido,
                style: tema.textTheme.headlineSmall,
              ),
              if (minutos != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Llevas $minutos min en esta entrega',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _Dato(
                icon: Icons.payments_outlined,
                titulo: 'Total',
                valor: CurrencyFormatter.format(widget.pedido.total),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: PrimaryButton(
              label: 'Marcar como entregado',
              isLoading: acciones.completando,
              onPressed: _completar,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.titulo, required this.valor});

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

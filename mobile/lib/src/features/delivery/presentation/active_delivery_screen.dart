import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/external/enlaces_externos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/location_urls.dart';
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
    final latitud = widget.pedido.latitud;
    final longitud = widget.pedido.longitud;
    final destino = latitud != null && longitud != null
        ? LatLng(latitud, longitud)
        : null;

    return Column(
      children: [
        // Mitad superior: Mapa
        Expanded(
          flex: 4,
          child: _Mapa(zona: permisos, destino: destino),
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
              if (destino != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _BotonesApertura(
                  latitud: destino.latitude,
                  longitud: destino.longitude,
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

/// Mapa superior de la entrega activa: el destino solo se dibuja si el pedido
/// trae coordenadas; sin ellas se ofrece un aviso textual (07.5 §5).
class _Mapa extends ConsumerWidget {
  const _Mapa({required this.zona, required this.destino});

  final AsyncValue<LocationPermissionStatus> zona;
  final LatLng? destino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return zona.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(mensaje(e))),
      data: (status) {
        final permisosOk =
            status == LocationPermissionStatus.whenInUse ||
            status == LocationPermissionStatus.always;
        final puntoDestino = destino;
        if (puntoDestino == null) {
          return _AvisoMapa(
            texto: 'Este pedido no tiene coordenadas para mostrar en el mapa.',
            icono: Icons.place_outlined,
          );
        }
        if (!permisosOk) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 48,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Necesitamos tu ubicación para mostrar la ruta.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
        }
        return DeliveryMap(
          origin: const LatLng(13.6929, -89.2182), // QuickBite Centro
          destination: puntoDestino,
          routePolyline: const [],
          originTitle: 'QuickBite',
          destinationTitle: 'Cliente',
        );
      },
    );
  }
}

class _AvisoMapa extends StatelessWidget {
  const _AvisoMapa({required this.texto, required this.icono});

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 48, color: AppColors.inkSoft),
            const SizedBox(height: AppSpacing.md),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
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

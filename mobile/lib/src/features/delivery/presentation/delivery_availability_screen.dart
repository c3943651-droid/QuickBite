import '../../../core/theme/app_radius.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/disponibilidad.dart';
import 'delivery_providers.dart';

/// Disponibilidad del repartidor (07.1 SCR-DEL-07).
///
/// El interruptor no guarda nada por su cuenta: cada cambio va a la API y lo que
/// se repinta es la respuesta del servidor. Así no puede quedar desincronizado
/// con el backend, que es quien decide si el repartidor entra en la cola.
class DeliveryAvailabilityScreen extends ConsumerWidget {
  const DeliveryAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponibilidad = ref.watch(disponibilidadProvider);
    final cambio = ref.watch(cambiarDisponibilidadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: disponibilidad.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: mensaje(error),
          onRetry: () => ref.invalidate(disponibilidadProvider),
        ),
        data: (datos) => _Contenido(datos: datos, cambiando: cambio.cambiando),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.datos, required this.cambiando});

  final Disponibilidad datos;
  final bool cambiando;

  Future<void> _cambiar(BuildContext context, WidgetRef ref, bool valor) async {
    final notifier = ref.read(cambiarDisponibilidadProvider.notifier);
    final ok = await notifier.cambiar(valor);
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(
        context,
        valor ? 'Ahora estás disponible' : 'Dejaste de estar disponible',
      );
      return;
    }
    // La API rechazó el cambio: se revierte el interruptor y se explica por qué.
    final error = ref.read(cambiarDisponibilidadProvider).error;
    notifier.limpiarError();
    AppSnackbar.showError(
      context,
      error ?? 'No se pudo cambiar tu disponibilidad',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 0,
          color: AppColors.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: SwitchListTile(
            value: datos.estaDisponible,
            onChanged: cambiando
                ? null
                : (valor) => _cambiar(context, ref, valor),
            title: const Text('Estoy disponible para recibir pedidos'),
            subtitle: Text('Estado actual: ${datos.estado.etiqueta}'),
          ),
        ),
        if (datos.tieneEntregaActiva) ...[
          const SizedBox(height: AppSpacing.lg),
          const _Aviso(),
        ],
      ],
    );
  }
}

/// Aviso de SCR-DEL-07: con entrega en curso no se puede estar disponible.
class _Aviso extends StatelessWidget {
  const _Aviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Tienes una entrega en curso. Mientras la tengas, no puede '
              'marcarse como disponible.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/polling/polling_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/notification_entities.dart';
import '../domain/preferencias_notificacion.dart';
import 'preferencias_providers.dart';

/// Preferencias de notificación (07.1 SCR-PROF-08).
///
/// Los cinco tipos, el sonido y la vibración son interruptores; la frecuencia
/// de actualización elige una de las tres opciones del polling (05#D-01). Todo
/// es local: la pantalla no habla con la API.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(preferenciasNotificacionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de notificaciones')),
      body: preferencias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          onRetry: () => ref.invalidate(preferenciasNotificacionProvider),
        ),
        data: (data) => _Body(preferencias: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.preferencias});

  final PreferenciasNotificacion preferencias;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(preferenciasNotificacionProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const _Seccion('Tipos de notificación'),
        _interruptor(
          context,
          etiqueta: 'Pedidos nuevos',
          activo: preferencias.pedidoNuevo,
          onChanged: (v) => notifier.actualizarTipo(
            TipoNotificacion.pedidoNuevo,
            v,
          ),
        ),
        _interruptor(
          context,
          etiqueta: 'Cambios de estado',
          activo: preferencias.cambioEstado,
          onChanged: (v) => notifier.actualizarTipo(
            TipoNotificacion.cambioEstado,
            v,
          ),
        ),
        _interruptor(
          context,
          etiqueta: 'Asignaciones',
          activo: preferencias.asignacion,
          onChanged: (v) => notifier.actualizarTipo(
            TipoNotificacion.asignacion,
            v,
          ),
        ),
        _interruptor(
          context,
          etiqueta: 'Sistema',
          activo: preferencias.sistema,
          onChanged: (v) =>
              notifier.actualizarTipo(TipoNotificacion.sistema, v),
        ),
        _interruptor(
          context,
          etiqueta: 'Recordatorios',
          activo: preferencias.recordatorio,
          onChanged: (v) => notifier.actualizarTipo(
            TipoNotificacion.recordatorio,
            v,
          ),
        ),
        const Divider(height: AppSpacing.xl),
        const _Seccion('Alertas'),
        _interruptor(
          context,
          etiqueta: 'Sonido',
          activo: preferencias.sonido,
          onChanged: notifier.cambiarSonido,
        ),
        _interruptor(
          context,
          etiqueta: 'Vibración',
          activo: preferencias.vibracion,
          onChanged: notifier.cambiarVibracion,
        ),
        const Divider(height: AppSpacing.xl),
        const _Seccion('Frecuencia de actualización'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (final opcion in FrecuenciaPolling.opciones)
                RadioListTile<Duration>(
                  value: opcion,
                  groupValue: _opcionSeleccionada(
                    preferencias.intervaloActualizacion,
                  ),
                  onChanged: (valor) {
                    if (valor != null) notifier.cambiarIntervalo(valor);
                  },
                  title: Text(_etiqueta(opcion)),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Text(
            'Afecta cada cuánto se actualiza el estado de tus pedidos. '
            'Menos consultas, menos batería.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// El valor guardado siempre está normalizado, así que se busca la opción
  /// exacta; si el almacenamiento trajera algo fuera del catálogo se marca la
  /// más cercana en lugar de dejar la sección sin selección.
  static Duration _opcionSeleccionada(Duration intervalo) {
    for (final opcion in FrecuenciaPolling.opciones) {
      if (opcion == intervalo) return opcion;
    }
    return FrecuenciaPolling.normalizar(intervalo);
  }

  static String _etiqueta(Duration intervalo) {
    if (intervalo == const Duration(seconds: 10)) return '10 segundos';
    if (intervalo == const Duration(seconds: 30)) return '30 segundos';
    if (intervalo == const Duration(minutes: 1)) return '1 minuto';
    return '${intervalo.inSeconds} segundos';
  }

  static Widget _interruptor(
    BuildContext context, {
    required String etiqueta,
    required bool activo,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(etiqueta),
    value: activo,
    onChanged: onChanged,
  );
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.quickbiteOrange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No pudimos leer tus preferencias.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

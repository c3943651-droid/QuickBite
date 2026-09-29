import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/preferencias_idioma.dart';
import '../domain/sesion_usuario.dart';
import 'idioma_providers.dart';
import 'security_providers.dart';

/// Sesiones activas (07.1 SCR-PROF-05).
///
/// La lista viene de `GET /users/sessions`, que ya marca cuál es la actual
/// (04 §4.9). La sesión en curso aparece igual que las demás pero sin botón de
/// revocar: cerrarla aquí dejaría al usuario fuera de la app sin poder
/// confirmarlo, que es justo lo que la ficha prohíbe.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesiones = ref.watch(sesionesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones activas')),
      body: switch (sesiones) {
        AsyncData(:final value) => value.isEmpty
            ? const EmptyStateView(
                message: 'No hay sesiones activas',
                icon: Icons.devices_other_outlined,
              )
            : _Lista(sesiones: value),
        AsyncError(:final error) => ErrorStateView(
            message: error is AppException
                ? error.userMessage
                : 'No pudimos cargar tus sesiones. Inténtalo de nuevo.',
            onRetry: () => ref.read(sesionesProvider.notifier).recargar(),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.sesiones});

  final List<SesionUsuario> sesiones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sesiones.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _Tarjeta(
        sesion: sesiones[index],
        // 07.1 SCR-PROF-10: las fechas y horas se pintan con el formato que el
        // usuario eligió en Idioma y región, no con uno fijo de la pantalla.
        formato: ref.watch(idiomaProvider).asData?.value,
        onRevocar: () => _revocar(context, ref, sesiones[index]),
      ),
    );
  }

  Future<void> _revocar(
    BuildContext context,
    WidgetRef ref,
    SesionUsuario sesion,
  ) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Revocar esta sesión?',
      message:
          'La sesión en ${sesion.direccion} tendrá que iniciar sesión de nuevo.',
      confirmLabel: 'Revocar',
      destructive: true,
    );
    if (!confirmado || !context.mounted) return;

    try {
      await ref.read(sesionesProvider.notifier).revocar(sesion.id);
      if (context.mounted) {
        AppSnackbar.showSuccess(context, 'Sesión revocada');
      }
    } on Object {
      if (context.mounted) {
        AppSnackbar.showError(context, 'No se pudo revocar la sesión');
      }
    }
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.sesion,
    required this.formato,
    required this.onRevocar,
  });

  final SesionUsuario sesion;
  final PreferenciasIdioma? formato;
  final VoidCallback onRevocar;

  /// Mientras se leen las preferencias se usa el formato de fábrica, que es el
  /// español, en vez de dejar la fecha sin pintar.
  PreferenciasIdioma get _preferencias => formato ?? const PreferenciasIdioma();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sesion.dispositivo,
                    style: texto.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sesion.esActual)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.quickbiteOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      'Esta sesión',
                      style: texto.labelSmall?.copyWith(
                        color: AppColors.quickbiteOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(sesion.direccion, style: texto.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Emitida ${_preferencias.formatearFechaHora(sesion.creadoEn.toLocal())}',
              style: texto.bodySmall,
            ),
            Text(
              'Expira ${_preferencias.formatearFechaHora(sesion.expiraEn.toLocal())}',
              style: texto.bodySmall,
            ),
            if (sesion.puedeRevocarse) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRevocar,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Revocar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

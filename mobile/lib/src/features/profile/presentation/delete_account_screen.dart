import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/external/enlaces_externos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_providers.dart';

/// Eliminar la cuenta (07.1 SCR-PROF-15, decisión 05#D-04).
///
/// Aquí no hay botón de borrar: el derecho al olvido se cumple como un
/// procedimiento manual. La pantalla explica los pasos, muestra los datos que
/// se van a eliminar y abre el correo con la solicitud ya redactada. Borrar en
/// el acto dejaría al usuario sin copia de sus pedidos y sin Directions.
class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  static const _pasos = <String>[
    'Escríbenos desde este correo con tu nombre y el de tu cuenta.',
    'Confirmamos por email que la solicitud es tuya.',
    'Borramos tus datos en un máximo de 30 días naturales.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(userProfileProvider).asData?.value;
    final email = perfil?.email ?? 'tu correo';
    final nombre = perfil?.nombre ?? 'tu cuenta';

    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.errorRed.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.errorRed),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'La eliminación es manual',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'La app no puede borrar tu cuenta por ti. Cuando envíes la '
                  'solicitud, el equipo la revisa a mano y borra tus datos. '
                  'Mientras tanto tu cuenta sigue activa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _pasos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.quickbiteOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_pasos[i])),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se eliminará',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tu cuenta $nombre ($email), tus pedidos, tus direcciones y '
                    'tus datos personales.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Contactar para eliminar mi cuenta',
            icon: Icons.mail_outline,
            onPressed: () => _solicitar(context, ref, email, nombre),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Se abrirá tu app de correo con el mensaje preparado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Future<void> _solicitar(
    BuildContext context,
    WidgetRef ref,
    String email,
    String nombre,
  ) async {
    final enviado = await ref.read(enlacesExternosProvider).solicitarEliminacionCuenta(
      emailUsuario: email,
      nombreUsuario: nombre,
    );
    if (!context.mounted || enviado) return;
    AppSnackbar.showError(context, 'No se pudo abrir tu app de correo.');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/external/enlaces_externos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/settings_tile.dart';

/// Privacidad (07.1 SCR-PROF-11).
///
/// Todo lo que se abre aquí es documentación: la app no guarda datos ni pide
/// permisos de forma silenciosa, así que basta con poder abrir los textos y
/// decir qué permisos existen.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  /// Permisos que la app puede usar. Se listan aunque no se hayan concedido:
  /// el usuario tiene que saber qué podría pedirse, no solo lo que ya pidió.
  static const permisos = <({String nombre, String paraQueSirve})>[
    (
      nombre: 'Cámara',
      paraQueSirve: 'Solo si capturas una foto al reportar un problema.',
    ),
    (
      nombre: 'Almacenamiento',
      paraQueSirve:
          'Para guardar las exportaciones de datos en tu dispositivo.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SectionHeader('Información legal'),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            subtitle: 'Qué datos guarda QuickBite y durante cuánto tiempo.',
            onTap: () => _abrirDocumento(
              context,
              ref,
              EnlacesExternos.politicaPrivacidad,
            ),
          ),
          SettingsTile(
            icon: Icons.gavel_outlined,
            label: 'Términos de uso',
            subtitle: 'Las reglas de uso de la app.',
            onTap: () =>
                _abrirDocumento(context, ref, EnlacesExternos.terminosUso),
          ),
          const SectionHeader('Permisos de la app'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'QuickBite no pide permisos que no necesite. Estos son los únicos '
              'que puede pedirte y para qué:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final permiso in permisos)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(permiso.nombre),
              subtitle: Text(
                permiso.paraQueSirve,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: AppSpacing.xl),
          SettingsTile(
            icon: Icons.data_usage_outlined,
            label: 'Uso de datos',
            subtitle:
                'Qué datos recogemos, para qué y cuánto tiempo los guardamos.',
            onTap: () =>
                _abrirDocumento(context, ref, EnlacesExternos.usoDeDatos),
          ),
        ],
      ),
    );
  }

  /// Si el dispositivo no puede abrir el documento se dice: un silencio aquí
  /// parece un botón roto.
  static Future<void> _abrirDocumento(
    BuildContext context,
    WidgetRef ref,
    String slug,
  ) async {
    final abierto = await ref
        .read(enlacesExternosProvider)
        .abrirDocumento(slug);
    if (!context.mounted || abierto) return;
    AppSnackbar.showError(
      context,
      'No se pudo abrir el documento. Revisa tu conexión o inténtalo más tarde.',
    );
  }
}

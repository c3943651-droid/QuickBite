import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/preferencias_idioma.dart';
import 'idioma_providers.dart';

/// Idioma y región (07.1 SCR-PROF-10).
///
/// El idioma se muestra pero no se elige: en v1.0 el español es el único
/// disponible y una lista con una opción solo confunde. Los dos formatos sí se
/// eligen, y al cambiarlos se ve el efecto de inmediato en fechas y horas.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(idiomaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Idioma y región')),
      body: preferencias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: error is AppException
              ? error.userMessage
              : 'No pudimos leer tus preferencias de idioma.',
          onRetry: () => ref.invalidate(idiomaProvider),
        ),
        data: (data) => _Body(preferencias: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.preferencias});

  final PreferenciasIdioma preferencias;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(idiomaProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SectionHeader('Idioma'),
        ListTile(
          title: Text(preferencias.idioma.etiqueta),
          subtitle: const Text(
            'Español es el único idioma disponible en la v1.0.',
          ),
          trailing: const Icon(Icons.check, color: AppColors.successGreen),
        ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Formato de fecha'),
        for (final formato in FormatoFecha.values)
          RadioListTile<FormatoFecha>(
            value: formato,
            // ignore: deprecated_member_use
            groupValue: preferencias.formatoFecha,
            // ignore: deprecated_member_use
            onChanged: (valor) {
              if (valor != null) notifier.cambiarFormatoFecha(valor);
            },
            title: Text(formato.etiqueta),
            contentPadding: EdgeInsets.zero,
          ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Formato de hora'),
        for (final formato in FormatoHora.values)
          RadioListTile<FormatoHora>(
            value: formato,
            // ignore: deprecated_member_use
            groupValue: preferencias.formatoHora,
            // ignore: deprecated_member_use
            onChanged: (valor) {
              if (valor != null) notifier.cambiarFormatoHora(valor);
            },
            title: Text(formato.etiqueta),
            contentPadding: EdgeInsets.zero,
          ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Moneda'),
        const SettingsTile(
          icon: Icons.payments_outlined,
          label: 'Peso mexicano (MXN)',
          subtitle: 'La moneda es fija: no se puede cambiar en la v1.0.',
        ),
      ],
    );
  }
}

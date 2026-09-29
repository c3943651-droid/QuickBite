import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/preferencias_apariencia.dart';
import 'apariencia_providers.dart';

/// Apariencia (07.1 SCR-PROF-09).
///
/// Cinco secciones, todas locales: tema, tamaño de texto, contraste, reducción
/// de animaciones y modo daltónico. Cada cambio se ve en la propia pantalla
/// porque el `MaterialApp` de la app observa el mismo provider, así que no hace
/// falta un botón de "aplicar" ni un aviso al salir.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencias = ref.watch(aparienciaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: preferencias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: error is AppException
              ? error.userMessage
              : 'No pudimos leer tus preferencias de apariencia.',
          onRetry: () => ref.invalidate(aparienciaProvider),
        ),
        data: (data) => _Body(preferencias: data),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.preferencias});

  final PreferenciasApariencia preferencias;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(aparienciaProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SectionHeader('Tema'),
        _opciones<TemaApp>(
          valores: TemaApp.values,
          seleccionada: preferencias.tema,
          etiqueta: (opcion) => opcion.etiqueta,
          onChanged: notifier.cambiarTema,
        ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Tamaño de texto'),
        _opciones<TamanoTexto>(
          valores: TamanoTexto.values,
          seleccionada: preferencias.tamanoTexto,
          etiqueta: (opcion) => opcion.etiqueta,
          onChanged: notifier.cambiarTamanoTexto,
        ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Contraste'),
        SwitchListTile(
          title: const Text('Alto contraste'),
          subtitle: Text(
            'Sube el contraste del texto y de los bordes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: preferencias.altoContraste,
          onChanged: (v) => notifier.cambiarContraste(
            v ? Contraste.alto : Contraste.normal,
          ),
        ),
        SwitchListTile(
          title: const Text('Reducir animaciones'),
          subtitle: Text(
            'Quita transiciones y movimiento de la app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: preferencias.reducirAnimaciones,
          onChanged: notifier.cambiarReducirAnimaciones,
        ),
        const Divider(height: AppSpacing.xl),
        const SectionHeader('Modo daltónico'),
        _opciones<ModoDaltonismo>(
          valores: ModoDaltonismo.values,
          seleccionada: preferencias.modoDaltonismo,
          etiqueta: (opcion) => opcion.etiqueta,
          onChanged: notifier.cambiarModoDaltonismo,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Text(
            'Sustituye los colores que no distingues por otros equivalentes. '
            'La paleta es provisional y puede cambiar en próximas versiones.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  static Widget _opciones<T>({
    required List<T> valores,
    required T seleccionada,
    required String Function(T) etiqueta,
    required ValueChanged<T> onChanged,
  }) => Column(
    children: [
      for (final opcion in valores)
        RadioListTile<T>(
          value: opcion,
          // ignore: deprecated_member_use
          groupValue: seleccionada,
          // ignore: deprecated_member_use
          onChanged: (valor) {
            if (valor != null) onChanged(valor);
          },
          title: Text(etiqueta(opcion)),
          contentPadding: EdgeInsets.zero,
        ),
    ],
  );
}


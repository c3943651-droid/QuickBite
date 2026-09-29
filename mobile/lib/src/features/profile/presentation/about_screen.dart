import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/external/enlaces_externos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/settings_tile.dart';

/// Versión y build, envueltos para que la pantalla no dependa del plugin
/// (`PackageInfo` es una clase estática y no se puede sobrescribir en un test).
final appInfoProvider = FutureProvider<AppInfo>(
  (ref) => AppInfo.leer(),
  retry: (_, _) => null,
);

class AppInfo {
  const AppInfo({
    required this.version,
    required this.build,
    required this.packageName,
  });

  final String version;
  final String build;
  final String packageName;

  static Future<AppInfo> leer() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      version: info.version,
      build: info.buildNumber,
      packageName: info.packageName,
    );
  }
}

/// Acerca de (07.1 SCR-PROF-13).
///
/// La versión sale del propio paquete instalado (`package_info_plus`) para que
/// no haya que acordarse de subir un número a mano en cada entrega.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.quickbiteOrange,
                    borderRadius: BorderRadius.circular(AppRadius.image),
                  ),
                  child: const Icon(
                    Icons.lunch_dining,
                    size: 56,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('QuickBite', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                info.when(
                  loading: () => const Text('Leyendo la versión…'),
                  error: (error, _) => const Text('Versión no disponible'),
                  data: (data) => Text(
                    'Versión ${data.version} · build ${data.build}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),
          const SectionHeader('Créditos'),
          const ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Equipo de desarrollo'),
            subtitle: Text('quickbite.mx'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Tecnologías'),
            subtitle: Text('Flutter, Dart, .NET 8, PostgreSQL y Supabase.'),
          ),
          const Divider(height: AppSpacing.xl),
          SettingsTile(
            icon: Icons.article_outlined,
            label: 'Licencias de código abierto',
            subtitle: 'Ver los paquetes de terceros que usa la app.',
            onTap: () => _abrir(
              context,
              ref,
              ref.read(enlacesExternosProvider).abrirLicencias(),
            ),
          ),
          SettingsTile(
            icon: Icons.gavel_outlined,
            label: 'Términos de uso',
            onTap: () => _abrir(
              context,
              ref,
              ref
                  .read(enlacesExternosProvider)
                  .abrirDocumento(EnlacesExternos.terminosUso),
            ),
          ),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () => _abrir(
              context,
              ref,
              ref
                  .read(enlacesExternosProvider)
                  .abrirDocumento(EnlacesExternos.politicaPrivacidad),
            ),
          ),
        ],
      ),
    );
  }

  /// Si el dispositivo no puede abrir nada se avisa, en vez de dejar filas que
  /// parecen rotas.
  static Future<void> _abrir(
    BuildContext context,
    WidgetRef ref,
    Future<bool> abierto,
  ) async {
    if (await abierto || !context.mounted) return;
    AppSnackbar.showError(context, 'No se pudo abrir el documento.');
  }
}

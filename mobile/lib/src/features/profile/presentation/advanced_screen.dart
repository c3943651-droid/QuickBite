import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/images/image_cache_cleaner.dart';
import 'package:quickbite_mobile/src/core/widgets/app_snackbar.dart';
import 'package:quickbite_mobile/src/core/widgets/confirm_dialog.dart';
import 'package:quickbite_mobile/src/core/widgets/settings_tile.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/preferencias_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_list_providers.dart';
import 'package:quickbite_mobile/src/features/profile/data/mantenimiento_repository.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/apariencia_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/idioma_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';

final imageCacheCleanerProvider = Provider<ImageCacheCleaner>(
  (ref) => const DefaultImageCacheCleaner(),
);

final mantenimientoRepositoryProvider = Provider<MantenimientoRepository>(
  (ref) => MantenimientoRepository(ref.watch(sharedPreferencesProvider)),
);

/// Escribe una exportación y devuelve dónde quedó.
///
/// Va detrás de una interfaz por la misma razón que [ExternalLauncher]: que la
/// pantalla no dependa del disco y el test no escriba en el equipo de quien lo
/// corre.
abstract interface class ExportadorDatos {
  Future<String> exportar({
    required String nombre,
    required Map<String, Object?> datos,
  });
}

class ExportadorDatosArchivo implements ExportadorDatos {
  const ExportadorDatosArchivo();

  @override
  Future<String> exportar({
    required String nombre,
    required Map<String, Object?> datos,
  }) async {
    final archivo = await MantenimientoRepository.exportar(
      nombre: nombre,
      datos: datos,
    );
    return archivo.path;
  }
}

final exportadorDatosProvider = Provider<ExportadorDatos>(
  (ref) => const ExportadorDatosArchivo(),
);

/// Qué dejó hecha una acción de mantenimiento, para que la pantalla pueda
/// avisar y, si hace falta, reponer lo que invalidó.
enum ResultadoMantenimiento { ok, fallo }

/// Avanzado (07.1 SCR-PROF-14).
///
/// Seis acciones locales. Las cuatro primeras piden confirmación porque borran
/// algo; las dos últimas generan un archivo. Ninguna llama a la API: lo que la
/// app guarda es caché y preferencias locales.
class AdvancedScreen extends ConsumerWidget {
  const AdvancedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avanzado')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const SectionHeader('Caché'),
          SettingsTile(
            icon: Icons.image_outlined,
            label: 'Limpiar caché de imágenes',
            subtitle: 'Las fotos de producto se vuelven a descargar al abrir la app.',
            onTap: () => _limpiarCacheImagenes(context, ref),
          ),
          const Divider(height: AppSpacing.xl),
          const SectionHeader('Datos locales'),
          SettingsTile(
            icon: Icons.cleaning_services_outlined,
            label: 'Limpiar datos locales',
            subtitle: 'Borra las preferencias guardadas en este dispositivo.',
            onTap: () => _limpiarDatosLocales(context, ref),
          ),
          SettingsTile(
            icon: Icons.history_toggle_off_outlined,
            label: 'Limpiar historial de búsquedas',
            subtitle: 'Olvida los términos que buscaste.',
            onTap: () => _limpiarHistorial(context, ref),
          ),
          SettingsTile(
            icon: Icons.settings_backup_restore_outlined,
            label: 'Restablecer preferencias',
            subtitle: 'Apariencia, idioma y notificaciones vuelven a su valor inicial.',
            onTap: () => _restablecer(context, ref),
          ),
          const Divider(height: AppSpacing.xl),
          const SectionHeader('Tus datos'),
          SettingsTile(
            icon: Icons.download_outlined,
            label: 'Exportar mis datos',
            subtitle: 'Genera un archivo con tu perfil, pedidos y direcciones.',
            onTap: () => _exportarDatos(context, ref),
          ),
          SettingsTile(
            icon: Icons.receipt_long_outlined,
            label: 'Exportar historial de pedidos',
            subtitle: 'Genera un archivo con el detalle de tus pedidos.',
            onTap: () => _exportarPedidos(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            child: Text(
              'Los archivos se guardan en el almacenamiento privado de la app, '
              'no en tu galería. Los pedidos y las direcciones no se borran aquí '
              'porque viven en el servidor.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarCacheImagenes(BuildContext context, WidgetRef ref) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Limpiar la caché de imágenes?',
      message: 'Se borrarán las fotos guardadas en el dispositivo.',
      confirmLabel: 'Sí, limpiar',
      destructive: true,
    );
    if (!confirmado || !context.mounted) return;

    await ref.read(imageCacheCleanerProvider).limpiar();
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Caché de imágenes limpia');
  }

  Future<void> _limpiarDatosLocales(BuildContext context, WidgetRef ref) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Limpiar los datos locales?',
      message: 'Se borrarán las preferencias guardadas en este dispositivo. '
          'No afecta a tus pedidos ni a tu cuenta.',
      confirmLabel: 'Sí, limpiar',
      destructive: true,
    );
    if (!confirmado || !context.mounted) return;

    await ref.read(mantenimientoRepositoryProvider).limpiarPreferencias();
    await _refrescarPreferencias(ref);
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Datos locales limpiados');
  }

  Future<void> _limpiarHistorial(BuildContext context, WidgetRef ref) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Borrar el historial de búsquedas?',
      message: 'Se olvidarán los términos que buscaste.',
      confirmLabel: 'Sí, borrar',
      destructive: true,
    );
    if (!confirmado || !context.mounted) return;

    await ref.read(searchHistoryProvider.notifier).clear();
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Historial borrado');
  }

  Future<void> _restablecer(BuildContext context, WidgetRef ref) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Restablecer las preferencias?',
      message: 'Aparencia, idioma y notificaciones volverán a su valor inicial.',
      confirmLabel: 'Sí, restablecer',
      destructive: true,
    );
    if (!confirmado || !context.mounted) return;

    await ref.read(aparienciaProvider.notifier).restablecer();
    await ref.read(idiomaProvider.notifier).restablecer();
    await ref.read(preferenciasNotificacionProvider.notifier).restablecer();
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Preferencias restablecidas');
  }

  Future<void> _exportarDatos(BuildContext context, WidgetRef ref) async {
    final perfil = ref.read(userProfileProvider).asData?.value;
    final pedidos = ref.read(ordersProvider).asData?.value ?? const <Order>[];

    await _exportar(
      context,
      ref,
      nombre: 'mis-datos',
      datos: {
        'perfil': _perfil(perfil),
        'pedidos': pedidos.map(_pedido).toList(),
        'exportado_desde': 'QuickBite ${perfil?.email ?? 'sin sesión'}',
      },
    );
  }

  Future<void> _exportarPedidos(BuildContext context, WidgetRef ref) async {
    final pedidos = ref.read(ordersProvider).asData?.value ?? const <Order>[];

    await _exportar(
      context,
      ref,
      nombre: 'mis-pedidos',
      datos: {'pedidos': pedidos.map(_pedido).toList()},
    );
  }

  Future<void> _exportar(
    BuildContext context,
    WidgetRef ref, {
    required String nombre,
    required Map<String, Object?> datos,
  }) async {
    try {
      final ruta = await ref
          .read(exportadorDatosProvider)
          .exportar(nombre: nombre, datos: datos);
      if (!context.mounted) return;
      _mostrarArchivo(context, ruta);
    } on Object {
      if (!context.mounted) return;
      AppSnackbar.showError(
        context,
        'No se pudo generar el archivo. Inténtalo de nuevo.',
      );
    }
  }

  /// La ruta se muestra porque sin un selector de archivos el usuario no tiene
  /// forma de encontrar la exportación.
  static void _mostrarArchivo(BuildContext context, String ruta) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archivo generado'),
        content: SelectableText(ruta),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
      ),
    );
  }

  static Map<String, Object?> _perfil(UserProfile? perfil) => {
    if (perfil != null) 'id': perfil.id,
    if (perfil != null) 'nombre': perfil.nombre,
    if (perfil != null) 'email': perfil.email,
    if (perfil != null) 'rol': perfil.rol,
  };

  static Map<String, Object?> _pedido(Order pedido) => {
    'id': pedido.id,
    'numero_pedido': pedido.numeroPedido,
    'estado': pedido.estado,
    'total': pedido.total,
    'direccion_entrega': pedido.direccionEntrega,
    if (pedido.creadoEn != null)
      'creado_en': pedido.creadoEn!.toIso8601String(),
    'items': pedido.items
        .map((i) => {'nombre': i.nombre, 'cantidad': i.cantidad})
        .toList(),
  };

  /// Vuelve a leer las preferencias desde el almacenamiento.
  ///
  /// Invalidar los providers es necesario porque noifier, repositorio y
  /// `SharedPreferences` guardan su propia copia del valor.
  static Future<void> _refrescarPreferencias(WidgetRef ref) async {
    ref
      ..invalidate(aparienciaProvider)
      ..invalidate(idiomaProvider)
      ..invalidate(preferenciasNotificacionProvider);
  }
}

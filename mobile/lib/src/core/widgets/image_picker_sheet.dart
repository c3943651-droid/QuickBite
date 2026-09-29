import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../images/seleccion_imagen.dart';
import '../theme/app_colors.dart';
import 'app_bottom_sheet.dart';

/// Hoja modal de selección de imagen (07.1 SCR-COM-04).
///
/// Devuelve la ruta elegida, o `null` si se cancela o si la persona usuaria
/// descarta la selección dentro de la cámara o la galería.
Future<String?> mostrarSelectorImagen(BuildContext context) async {
  final origen = await AppBottomSheet.show<OrigenImagen>(
    context,
    title: 'Selecciona una imagen',
    child: const _OpcionesImagen(),
  );
  if (origen == null || !context.mounted) return null;
  return ProviderScope.containerOf(
    context,
    listen: false,
  ).read(selectorImagenProvider).seleccionar(origen);
}

class _OpcionesImagen extends StatelessWidget {
  const _OpcionesImagen();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Opcion(
          icon: Icons.photo_camera_outlined,
          label: 'Cámara',
          onTap: () => Navigator.of(context).pop(OrigenImagen.camara),
        ),
        _Opcion(
          icon: Icons.photo_library_outlined,
          label: 'Galería',
          onTap: () => Navigator.of(context).pop(OrigenImagen.galeria),
        ),
        _Opcion(
          icon: Icons.close,
          label: 'Cancelar',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.quickbiteOrange),
      title: Text(label),
      onTap: onTap,
    );
  }
}

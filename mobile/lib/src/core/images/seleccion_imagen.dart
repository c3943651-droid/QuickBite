import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// De dónde salió la imagen elegida (07.1 SCR-COM-04).
enum OrigenImagen { camara, galeria }

/// Elección de una imagen del dispositivo.
///
/// Interfaz y no `ImagePicker` directo para que las pruebas no dependan de la
/// cámara ni de la galería reales, igual que se hizo con el lanzador de enlaces
/// externos.
abstract interface class SelectorImagen {
  /// Ruta del archivo elegido, o `null` si la persona usuaria cancela.
  Future<String?> seleccionar(OrigenImagen origen);
}

class ImagePickerSelectorImagen implements SelectorImagen {
  ImagePickerSelectorImagen([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> seleccionar(OrigenImagen origen) async {
    final archivo = await _picker.pickImage(
      source: switch (origen) {
        OrigenImagen.camara => ImageSource.camera,
        OrigenImagen.galeria => ImageSource.gallery,
      },
      // Una foto de cámara de un teléfono actual pesa varios MB; recortarla en
      // el dispositivo evita subirla por la red para nada.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    return archivo?.path;
  }
}

final selectorImagenProvider = Provider<SelectorImagen>(
  (ref) => ImagePickerSelectorImagen(),
);

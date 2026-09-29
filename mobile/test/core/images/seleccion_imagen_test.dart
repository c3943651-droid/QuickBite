import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:quickbite_mobile/src/core/images/seleccion_imagen.dart';

void main() {
  late FakeImagePickerPlatform platform;

  setUp(() {
    platform = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = platform;
  });

  group('ImagePickerSelectorImagen', () {
    test('camara pide el origen camara y devuelve la ruta', () async {
      platform.resultado = FakeXFile('/tmp/foto.jpg');

      final ruta = await ImagePickerSelectorImagen().seleccionar(OrigenImagen.camara);

      expect(ruta, '/tmp/foto.jpg');
      expect(platform.fuentes, [ImageSource.camera]);
    });

    test('galeria pide el origen galeria y devuelve la ruta', () async {
      platform.resultado = FakeXFile('/tmp/galeria.png');

      final ruta = await ImagePickerSelectorImagen().seleccionar(OrigenImagen.galeria);

      expect(ruta, '/tmp/galeria.png');
      expect(platform.fuentes, [ImageSource.gallery]);
    });

    test('devuelve null si la persona usuaria cancela', () async {
      platform.resultado = null;

      final ruta = await ImagePickerSelectorImagen().seleccionar(OrigenImagen.camara);

      expect(ruta, isNull);
    });

    test('limita el tamaño para no subir imagenes de camara de varios MB', () async {
      platform.resultado = FakeXFile('/tmp/foto.jpg');

      await ImagePickerSelectorImagen().seleccionar(OrigenImagen.camara);

      expect(platform.maxWidth, 1280);
      expect(platform.maxHeight, 1280);
      expect(platform.imageQuality, 85);
    });
  });
}

class FakeXFile extends XFile {
  FakeXFile(super.path);
}

class FakeImagePickerPlatform extends ImagePickerPlatform {
  FakeXFile? resultado;
  final List<ImageSource> fuentes = [];
  double? maxWidth;
  double? maxHeight;
  int? imageQuality;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    fuentes.add(source);
    maxWidth = options.maxWidth;
    maxHeight = options.maxHeight;
    imageQuality = options.imageQuality;
    return resultado;
  }
}

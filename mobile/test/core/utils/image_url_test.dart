import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/utils/image_url.dart';

/// El panel de admin guarda la imagen como la escribe quien la sube: puede ser
/// absoluta (`https://cdn.../x.jpg`) o relativa al servidor
/// (`/uploads/productos/x.jpg`). Las relativas hay que pegarlas al **origen** del
/// API: `apiBaseUrl` ya trae `/api/v1`, que no forma parte de la ruta del
/// fichero estático.
void main() {
  const base = 'https://quickbite-n1bk.onrender.com/api/v1';

  group('resolverUrlImagen', () {
    test('devuelve null si no hay imagen', () {
      expect(resolverUrlImagen(null, apiBaseUrl: base), isNull);
      expect(resolverUrlImagen('', apiBaseUrl: base), isNull);
      expect(resolverUrlImagen('   ', apiBaseUrl: base), isNull);
    });

    test('deja intactas las URLs absolutas', () {
      expect(
        resolverUrlImagen('https://cdn.quickbite.mx/x.jpg', apiBaseUrl: base),
        'https://cdn.quickbite.mx/x.jpg',
      );
      expect(
        resolverUrlImagen('http://cdn.quickbite.mx/x.jpg', apiBaseUrl: base),
        'http://cdn.quickbite.mx/x.jpg',
      );
    });

    test('pega una ruta relativa al origen del API, no a apiBaseUrl', () {
      expect(
        resolverUrlImagen('/uploads/productos/x.jpg', apiBaseUrl: base),
        'https://quickbite-n1bk.onrender.com/uploads/productos/x.jpg',
      );
    });

    test('añade la barra inicial si falta', () {
      expect(
        resolverUrlImagen('uploads/productos/x.jpg', apiBaseUrl: base),
        'https://quickbite-n1bk.onrender.com/uploads/productos/x.jpg',
      );
    });

    test('respeta el puerto del backend local', () {
      expect(
        resolverUrlImagen(
          '/uploads/x.jpg',
          apiBaseUrl: 'http://localhost:5017/api/v1',
        ),
        'http://localhost:5017/uploads/x.jpg',
      );
    });

    test('conserva los query params de la ruta relativa', () {
      expect(
        resolverUrlImagen('/uploads/x.jpg?v=2', apiBaseUrl: base),
        'https://quickbite-n1bk.onrender.com/uploads/x.jpg?v=2',
      );
    });

    test('si la base no es una URL válida, devuelve la ruta tal cual', () {
      expect(
        resolverUrlImagen('/uploads/x.jpg', apiBaseUrl: 'no-es-una-url'),
        '/uploads/x.jpg',
      );
    });
  });
}

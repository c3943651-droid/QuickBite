/// Resuelve la URL de una imagen del API.
///
/// El backend guarda en `ImagenUrl` lo que se escribió al subirla, así que
/// puede venir absoluta (`https://cdn.quickbite.mx/x.jpg`) o como ruta del
/// servidor (`/uploads/productos/x.jpg`). Las relativas se pegan al **origen**
/// del API y no a `apiBaseUrl` completo, porque `apiBaseUrl` ya incluye
/// `/api/v1` y los ficheros estáticos no cuelgan de ese prefijo.
///
/// Sin esto, una ruta relativa llega a `CachedNetworkImage` tal cual y la
/// pantalla cae siempre en el icono de placeholder.
String? resolverUrlImagen(String? url, {required String apiBaseUrl}) {
  final limpia = url?.trim();
  if (limpia == null || limpia.isEmpty) {
    return null;
  }

  // Ya absoluta (http, https, data...). Se respeta tal cual: la CDN puede vivir
  // en otro dominio.
  if (limpia.contains('://')) {
    return limpia;
  }

  final Uri base;
  try {
    base = Uri.parse(apiBaseUrl);
  } on FormatException {
    return limpia;
  }
  if (!base.hasScheme || base.host.isEmpty) {
    return limpia;
  }

  final ruta = limpia.startsWith('/') ? limpia : '/$limpia';
  return Uri.parse(base.origin).resolve(ruta).toString();
}

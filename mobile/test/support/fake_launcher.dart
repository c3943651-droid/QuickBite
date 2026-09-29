import 'package:quickbite_mobile/src/core/external/enlaces_externos.dart';

/// Doble de [ExternalLauncher] que registra lo que la pantalla intentó abrir, para
/// poder comprobar el destino sin navegador ni plugin de plataforma.
class FakeExternalLauncher implements ExternalLauncher {
  final List<Uri> uris = [];

  /// Permite simular un dispositivo sin navegador o sin app de correo.
  bool puedeAbrir = true;

  @override
  Future<bool> abrir(Uri uri) async {
    uris.add(uri);
    return puedeAbrir;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Apertura de contenido externo.
///
/// Es una interfaz para que las pruebas no dependan de una app real: las
/// pantallas de privacidad, ayuda, acerca de y eliminación de cuenta solo saben
/// que piden abrir un [Uri], no que hay un navegador detrás.
abstract interface class ExternalLauncher {
  /// Devuelve `false` si no se pudo abrir, para que la pantalla lo diga en vez
  /// de fallar en silencio.
  Future<bool> abrir(Uri uri);
}

class UrlLauncherExternalLauncher implements ExternalLauncher {
  const UrlLauncherExternalLauncher();

  @override
  Future<bool> abrir(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final externalLauncherProvider = Provider<ExternalLauncher>(
  (ref) => const UrlLauncherExternalLauncher(),
);

/// Abre documentos legales y correos de soporte (07.1 SCR-PROF-11/12/15).
///
/// Centraliza los destinos para que ninguna pantalla construya una URL a mano y
/// todas respeten la configuración.
class EnlacesExternos {
  const EnlacesExternos(this._launcher, this._config);

  final ExternalLauncher _launcher;
  final AppConfig _config;

  static const politicaPrivacidad = 'privacidad';
  static const terminosUso = 'terminos';
  static const usoDeDatos = 'uso-de-datos';
  static const licencias = 'licencias';

  String get email => _config.supportEmail;

  Future<bool> abrirDocumento(String slug) =>
      _launcher.abrir(_config.documentoLegal(slug));

  Future<bool> abrirLicencias() => abrirDocumento(licencias);

  Future<bool> escribirSoporte({
    required String asunto,
    String cuerpo = '',
  }) => _launcher.abrir(_config.correo(asunto: asunto, cuerpo: cuerpo));

  /// Pide la eliminación de la cuenta. El cuerpo va prellenado con los datos
  /// que el usuario ya ve en la pantalla para no tener que escribirlos otra vez.
  Future<bool> solicitarEliminacionCuenta({
    required String emailUsuario,
    required String nombreUsuario,
  }) => escribirSoporte(
    asunto: 'Solicitud de eliminación de cuenta',
    cuerpo: '''
Hola, solicito la eliminación de mi cuenta de QuickBite.

Nombre: $nombreUsuario
Correo: $emailUsuario

Entiendo que la solicitud se procesa de forma manual y que mis datos se
eliminarán en un plazo máximo de 30 días naturales.
''',
  );
}

final enlacesExternosProvider = Provider<EnlacesExternos>(
  (ref) => EnlacesExternos(
    ref.watch(externalLauncherProvider),
    ref.watch(appConfigProvider),
  ),
);

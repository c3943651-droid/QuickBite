import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.supportEmail,
    required this.legalBaseUrl,
    this.isDebug = false,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://quickbite-n1bk.onrender.com/api/v1',
      ),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      supportEmail: const String.fromEnvironment(
        'SUPPORT_EMAIL',
        defaultValue: 'soporte@quickbite.mx',
      ),
      legalBaseUrl: const String.fromEnvironment(
        'LEGAL_BASE_URL',
        defaultValue: 'https://quickbite.mx/legal',
      ),
      isDebug: const bool.fromEnvironment('DEBUG', defaultValue: false),
    );
  }

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool isDebug;

  /// Contacto para soporte, reportes y eliminación de cuenta (07.1
  /// SCR-PROF-12/15). Vive en configuración y no en el código para que cambiarlo
  /// sea un `--dart-define` y no un edit de código: hasta que el negocio lo
  /// defina, estos son los valores por defecto y hay que confirmarlos antes de
  /// publicar.
  final String supportEmail;

  /// Base de los documentos legales que se abren en el navegador (07.1
  /// SCR-PROF-11/13). Misma decisión: configurable, pendiente de confirmar.
  final String legalBaseUrl;

  bool get isProduction => !isDebug;

  Uri documentoLegal(String slug) => Uri.parse('$legalBaseUrl/$slug');

  /// `mailto:` con asunto y cuerpo prellenados, que es lo que piden las
  /// pantallas de soporte y de eliminación de cuenta.
  Uri correo({required String asunto, String cuerpo = ''}) => Uri(
    scheme: 'mailto',
    path: supportEmail,
    queryParameters: {'subject': asunto, if (cuerpo.isNotEmpty) 'body': cuerpo},
  );
}

/// La configuración viene del entorno en la app real; los tests la sobrescriben
/// con `appConfigProvider.overrideWithValue(...)` para no depender de los
/// valores por defecto.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

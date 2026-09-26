class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
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
      isDebug: const bool.fromEnvironment('DEBUG', defaultValue: false),
    );
  }

  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool isDebug;

  bool get isProduction => !isDebug;
}

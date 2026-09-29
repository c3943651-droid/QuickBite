import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/app.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/core/session/token_storage.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_http.dart';
import 'fake_token_storage.dart';

/// Base de las pruebas de flujo (07.3 H8.2).
///
/// Estas pruebas montan la app **real** —`QuickBiteApp` con su router, sus
/// repositorios, su interceptor de sesión y sus pantallas— y lo único que se
/// sustituye es el transporte HTTP. Por eso son de integración y no unitarias:
/// un error en el cableado de providers, en el guard por rol o en el
/// interceptor de sesión solo aparece aquí.
///
/// Lo que no cubren es la correspondencia con el servidor real; para eso están
/// los tests de integración del backend.
class AppHarness {
  late final FakeHttpAdapter http;
  late final InMemoryTokenStorage tokens;

  /// Monta la app y deja que la pantalla de arranque termine.
  ///
  /// [tokensIniciales] simula que la persona ya tenía sesión guardada de una
  /// sesión anterior: es el escenario de "abrir la app con el token caducado".
  static Future<AppHarness> montar(
    WidgetTester tester, {
    Map<String, Object> preferencias = const {},
    StoredSession? tokensIniciales,
  }) async {
    final harness = AppHarness();
    await harness.montarApp(
      tester,
      preferencias: preferencias,
      tokensIniciales: tokensIniciales,
    );
    return harness;
  }

  Future<void> montarApp(
    WidgetTester tester, {
    Map<String, Object> preferencias = const {},
    StoredSession? tokensIniciales,
  }) async {
    // `flutter_test_config.dart` solo cubre `test/`, así que los datos de
    // idioma se inicializan aquí para que estas pruebas recorran el mismo camino que
    // `lib/main.dart`.
    await initializeDateFormatting('es');
    SharedPreferences.setMockInitialValues(preferencias);
    final prefs = await SharedPreferences.getInstance();

    http = FakeHttpAdapter();
    tokens = InMemoryTokenStorage(
      accessToken: tokensIniciales?.accessToken,
      refreshToken: tokensIniciales?.refreshToken,
      expiresIn: tokensIniciales?.expiresIn ?? 3600,
    );

    // Estas métricas son para el host: equivalen a un móvil de referencia. En un
    // dispositivo real hay que llamar a `tester.view.resetPhysicalSize()` y
    // `resetDevicePixelRatio()` después de montar, o el árbol se layoutea en
    // 1080x2400 lógicos y el motor lo estampa al 40% en la pantalla real.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    // Sin esto el `MediaQuery` de los tests no tiene inset inferior y ninguna
    // `SafeArea` hace nada: en el Moto G15 (3 botones, 120 px) la barra flotante
    // se dibujaba bajo la barra de navegación del sistema. Reportar el inset
    // real hace que el arnés se parezca al dispositivo de verdad.
    tester.view.padding = const FakeViewPadding(top: 51, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 51, bottom: 48);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(configDePrueba),
        tokenStorageProvider.overrideWithValue(tokens),
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientAdapterProvider.overrideWithValue(http),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QuickBiteApp(),
      ),
    );
    await asentar(tester);
  }

  static const configDePrueba = AppConfig(
    apiBaseUrl: 'https://api.test',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 10),
    supportEmail: 'soporte@test.mx',
    legalBaseUrl: 'https://test.mx/legal',
  );
}

/// Avanza el reloj lo justo para que terminen las redirecciones y las
/// animaciones.
///
/// `pumpAndSettle` no sirve de forma general en esta app: hay timers vivos
/// (polling, debounce de la búsqueda) que vuelven a programar frames, así que
/// nunca llega un frame quieto.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Sesión guardada de una ejecución anterior, para probar el arranque con un
/// token que el servidor ya no acepta.
const sesionGuardada = StoredSession(
  accessToken: 'access-vencido',
  refreshToken: 'refresh-vencido',
  expiresIn: 3600,
);

/// Respuesta de `/auth/login` para un rol dado.
Map<String, Object> loginDe(String rol) => {
  'accessToken': 'access-$rol',
  'refreshToken': 'refresh-$rol',
  'expiresIn': 3600,
  'user': {
    'id': rol == 'repartidor'
        ? '44444444-4444-4444-4444-444444444444'
        : '33333333-3333-3333-3333-333333333333',
    'nombre': rol == 'repartidor' ? 'Luis García' : 'Carlos Pérez',
    'email': '$rol@quickbite.mx',
    'rol': rol,
  },
};

/// Cuerpo de un producto del catálogo, con la forma que espera `ProductDto`.
Map<String, Object?> producto({
  String id = 'p1',
  String nombre = 'Tacos al pastor',
  double precio = 150,
}) => {
  'id': id,
  'nombre': nombre,
  'descripcion': 'Tres tacos con piña',
  'precio': precio,
  'imagenUrl': null,
  'disponible': true,
  'stock': 20,
  'stockMinimo': 5,
  'categoria': {
    'id': 'c1',
    'nombre': 'Tacos',
    'descripcion': null,
    'orden': 1,
    'activo': true,
    'icon': null,
  },
};

/// Envolvtorio paginado que devuelve `PagedResponseDto`.
Map<String, Object?> pagina(List<Map<String, Object?>> data) => {
  'data': data,
  'total': data.length,
  'page': 1,
  'limit': 20,
  'totalPages': 1,
};

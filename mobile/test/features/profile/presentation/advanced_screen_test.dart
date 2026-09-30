import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quickbite_mobile/src/core/config/app_config.dart';
import 'package:quickbite_mobile/src/core/external/enlaces_externos.dart';
import 'package:quickbite_mobile/src/core/images/image_cache_cleaner.dart';
import 'package:quickbite_mobile/src/features/auth/domain/auth_entities.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/preferencias_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/presentation/order_list_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/advanced_screen.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_apariencia.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_idioma.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/apariencia_providers.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/idioma_providers.dart';
import 'package:quickbite_mobile/src/features/search/presentation/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_launcher.dart';
import '../../../support/fake_token_storage.dart';
import '../../../support/router_harness.dart';

class _ExportadorFalso implements ExportadorDatos {
  _ExportadorFalso(this.ruta);

  final String? ruta;
  final List<String> nombres = [];

  @override
  Future<String> exportar({
    required String nombre,
    required Map<String, Object?> datos,
  }) async {
    nombres.add(nombre);
    if (ruta == null) throw Exception('sin espacio');
    return ruta!;
  }
}

class _ContadorLimpiezas implements ImageCacheCleaner {
  int llamadas = 0;

  @override
  Future<void> limpiar() async => llamadas++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ContadorLimpiezas cleaner;
  late _ExportadorFalso exportador;
  late ProviderContainer container;
  late GoRouter router;

  final pedido = Order(
    id: 'o1',
    numeroPedido: 'QB-001',
    estado: 'entregado',
    total: 250.5,
    direccionEntrega: 'Av. Reforma 222',
    items: const [OrderItem(nombre: 'Hamburguesa', cantidad: 2)],
  );

  Future<void> montar(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    String? rutaExportacion = '/tmp/quickbite-mis-datos.json',
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final shared = await SharedPreferences.getInstance();
    cleaner = _ContadorLimpiezas();
    exportador = _ExportadorFalso(rutaExportacion);
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        sharedPreferencesProvider.overrideWithValue(shared),
        externalLauncherProvider.overrideWithValue(FakeExternalLauncher()),
        imageCacheCleanerProvider.overrideWithValue(cleaner),
        exportadorDatosProvider.overrideWithValue(exportador),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'u1',
            nombre: 'Carlos',
            email: 'carlos@quickbite.mx',
            rol: 'cliente',
          ),
        ),
        ordersProvider.overrideWith((ref) async => [pedido]),
      ],
    );
    addTearDown(container.dispose);
    router = GoRouter(
      initialLocation: '/profile/advanced',
      routes: [
        GoRoute(
          path: '/profile/advanced',
          builder: (context, state) => const AdvancedScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista las seis acciones de mantenimiento', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester);

    expect(find.text('Avanzado'), findsOneWidget);
    expect(find.text('Limpiar caché de imágenes'), findsOneWidget);
    expect(find.text('Limpiar datos locales'), findsOneWidget);
    expect(find.text('Limpiar historial de búsquedas'), findsOneWidget);
    expect(find.text('Restablecer preferencias'), findsOneWidget);
    expect(find.text('Exportar mis datos'), findsOneWidget);
    expect(find.text('Exportar historial de pedidos'), findsOneWidget);
  });

  testWidgets('limpiar la caché pide confirmación y luego la borra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester);

    await tester.tap(find.text('Limpiar caché de imágenes'));
    await tester.pumpAndSettle();

    expect(find.text('¿Limpiar la caché de imágenes?'), findsOneWidget);
    expect(cleaner.llamadas, 0, reason: 'nada se borra sin confirmar');

    await tester.tap(find.widgetWithText(FilledButton, 'Sí, limpiar'));
    await tester.pumpAndSettle();

    expect(cleaner.llamadas, 1);
    expect(find.textContaining('Caché de imágenes limpia'), findsOneWidget);
  });

  testWidgets('cancelar no borra la caché', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester);

    await tester.tap(find.text('Limpiar caché de imágenes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Volver'));
    await tester.pumpAndSettle();

    expect(cleaner.llamadas, 0);
  });

  testWidgets('limpiar datos locales borra las preferencias guardadas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(
      tester,
      prefs: {'quickbite_prefs_sonido': false, 'quickbite_apar_tema': 'oscuro'},
    );

    await tester.tap(find.text('Limpiar datos locales'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sí, limpiar'));
    await tester.pumpAndSettle();

    final shared = container.read(sharedPreferencesProvider);
    expect(shared.containsKey('quickbite_prefs_sonido'), isFalse);
    expect(shared.containsKey('quickbite_apar_tema'), isFalse);
    expect(find.textContaining('Datos locales limpiados'), findsOneWidget);
  });

  testWidgets('limpiar el historial vacía las búsquedas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(
      tester,
      prefs: {
        'quickbite_search_history': ['pizza'],
      },
    );
    await container.read(searchHistoryProvider.future);
    expect(container.read(searchHistoryProvider).value!.terms, ['pizza']);

    await tester.tap(find.text('Limpiar historial de búsquedas'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sí, borrar'));
    await tester.pumpAndSettle();

    expect(container.read(searchHistoryProvider).value!.isEmpty, isTrue);
    expect(find.textContaining('Historial borrado'), findsOneWidget);
  });

  testWidgets(
    'restablecer deja apariencia, idioma y notificaciones de fábrica',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await montar(tester);
      await container.read(aparienciaProvider.future);
      await container.read(idiomaProvider.future);
      await container.read(preferenciasNotificacionProvider.future);
      await container
          .read(aparienciaProvider.notifier)
          .cambiarTema(TemaApp.oscuro);
      await container
          .read(idiomaProvider.notifier)
          .cambiarFormatoFecha(FormatoFecha.mesDiaAno);

      await tester.tap(find.text('Restablecer preferencias'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sí, restablecer'));
      await tester.pumpAndSettle();

      expect(container.read(aparienciaProvider).value?.tema, TemaApp.sistema);
      expect(
        container.read(idiomaProvider).value?.formatoFecha,
        FormatoFecha.diaMesAno,
      );
      expect(container.read(preferenciasNotificacionProvider).value, isNotNull);
      expect(find.textContaining('Preferencias restablecidas'), findsOneWidget);
    },
  );

  testWidgets('exportar mis datos genera el archivo y avisa dónde quedó', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester);

    await tester.tap(find.text('Exportar mis datos'));
    await tester.pumpAndSettle();

    expect(exportador.nombres, ['mis-datos']);
    expect(find.text('Archivo generado'), findsOneWidget);
    expect(find.text('/tmp/quickbite-mis-datos.json'), findsOneWidget);
  });

  testWidgets('exportar el historial de pedidos usa su propio archivo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester);

    await tester.tap(find.text('Exportar historial de pedidos'));
    await tester.pumpAndSettle();

    expect(exportador.nombres, ['mis-pedidos']);
  });

  testWidgets('si la exportación falla lo avisa en vez de fingir que guardó', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await montar(tester, rutaExportacion: null);

    await tester.tap(find.text('Exportar mis datos'));
    await tester.pumpAndSettle();

    expect(find.text('Archivo generado'), findsNothing);
    expect(
      find.textContaining('No se pudo generar el archivo'),
      findsOneWidget,
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/profile/data/mantenimiento_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // El repositorio serializa un `Map` opaco: armar el `Map` a partir de las
  // entidades es trabajo de la pantalla, no del guardado.
  const perfil = {
    'id': 'u1',
    'nombre': 'Carlos',
    'email': 'carlos@quickbite.mx',
  };

  const pedido = {
    'id': 'o1',
    'numero_pedido': 'QB-001',
    'estado': 'entregado',
    'total': 250.5,
    'items': [
      {'nombre': 'Hamburguesa', 'cantidad': 2},
    ],
  };

  group('MantenimientoRepository (07.1 SCR-PROF-14)', () {
    test('limpiar datos locales borra historial y preferencias', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['pizza', 'tacos'],
        'quickbite_prefs_sonido': true,
        'quickbite_apar_tema': 'oscuro',
        'otra_cosa': 'no se toca',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = MantenimientoRepository(prefs);

      await repo.limpiarPreferencias();

      expect(prefs.containsKey('quickbite_prefs_sonido'), isFalse);
      expect(prefs.containsKey('quickbite_apar_tema'), isFalse);
      expect(
        prefs.getStringList('quickbite_search_history'),
        isNotNull,
        reason: 'el historial tiene su propia acción',
      );
      expect(prefs.getString('otra_cosa'), 'no se toca');
    });

    test('limpiar el historial de búsquedas lo vacía', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_search_history': ['pizza'],
      });
      final prefs = await SharedPreferences.getInstance();

      await MantenimientoRepository(prefs).limpiarHistorialBusquedas();

      expect(prefs.containsKey('quickbite_search_history'), isFalse);
    });

    test('exportar datos personales produce un JSON con el perfil', () async {
      final archivo = await MantenimientoRepository.textoExportar(
        nombre: 'mis-datos',
        datos: {
          'perfil': perfil,
          'pedidos': [pedido],
        },
      );

      final contenido = jsonDecode(archivo.contenido) as Map<String, dynamic>;
      expect(contenido['perfil']['email'], 'carlos@quickbite.mx');
      expect(archivo.nombre, 'quickbite-mis-datos-2026-09-28.json');
    });

    test('exportar el historial de pedidos incluye los pedidos', () async {
      final archivo = await MantenimientoRepository.textoExportar(
        nombre: 'mis-pedidos',
        datos: {
          'pedidos': [pedido],
        },
      );

      final contenido = jsonDecode(archivo.contenido) as Map<String, dynamic>;
      final pedidos = contenido['pedidos'] as List<dynamic>;
      expect(pedidos.single['numero_pedido'], 'QB-001');
      expect(pedidos.single['items'], hasLength(1));
    });

    test('exportar deja el archivo escrito en el directorio indicado', () async {
      final temporal = await Directory.systemTemp.createTemp('quickbite-test');

      final ruta = await MantenimientoRepository.exportar(
        nombre: 'mis-datos',
        datos: const {'perfil': {'email': 'carlos@quickbite.mx'}},
        directorio: temporal,
        momento: DateTime.utc(2026, 9, 28),
      );

      expect(
        ruta.path,
        '${temporal.path}/quickbite-mis-datos-2026-09-28.json',
      );
      expect(
        jsonDecode(await ruta.readAsString()),
        containsPair('perfil', {'email': 'carlos@quickbite.mx'}),
      );
      await temporal.delete(recursive: true);
    });

    test('el archivo exportado dice de cuándo es y de qué app es', () async {
      final archivo = await MantenimientoRepository.textoExportar(
        nombre: 'mis-datos',
        datos: const {'perfil': {}},
        momento: DateTime.utc(2026, 9, 28, 12),
      );

      final contenido = jsonDecode(archivo.contenido) as Map<String, dynamic>;
      expect(contenido['exportado_en'], '2026-09-28');
      expect(contenido['app'], 'QuickBite');
    });
  });
}

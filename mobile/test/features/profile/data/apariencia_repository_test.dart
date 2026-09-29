import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/profile/data/apariencia_repository.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_apariencia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  group('AparienciaRepository (07.1 SCR-PROF-09)', () {
    test('sin nada guardado devuelve los valores por defecto', () async {
      final repo = AparienciaRepository(preferences);

      expect(await repo.read(), const PreferenciasApariencia());
      expect((await repo.read()).tema, TemaApp.sistema);
      expect((await repo.read()).tamanoTexto, TamanoTexto.normal);
      expect((await repo.read()).contraste, Contraste.normal);
      expect((await repo.read()).reducirAnimaciones, isFalse);
      expect((await repo.read()).modoDaltonismo, ModoDaltonismo.normal);
    });

    test('guarda y recupera las cinco preferencias', () async {
      final repo = AparienciaRepository(preferences);

      await repo.save(
        const PreferenciasApariencia(
          tema: TemaApp.oscuro,
          tamanoTexto: TamanoTexto.muyGrande,
          contraste: Contraste.alto,
          reducirAnimaciones: true,
          modoDaltonismo: ModoDaltonismo.protanopia,
        ),
      );

      expect(
        await repo.read(),
        const PreferenciasApariencia(
          tema: TemaApp.oscuro,
          tamanoTexto: TamanoTexto.muyGrande,
          contraste: Contraste.alto,
          reducirAnimaciones: true,
          modoDaltonismo: ModoDaltonismo.protanopia,
        ),
      );
    });

    test('una clave con otro tipo no tumba el resto de la lectura', () async {
      // Una clave escrita por una versión anterior o corrupta no puede dejar la
      // pantalla entera sin preferencias.
      SharedPreferences.setMockInitialValues({
        'quickbite_apar_tema': 42,
        'quickbite_apar_contraste': 'sí',
        'quickbite_apar_tamano': 3.5,
        'quickbite_apar_daltonismo': 7,
      });
      final prefs = await SharedPreferences.getInstance();

      final leidas = await AparienciaRepository(prefs).read();

      expect(leidas.tema, TemaApp.sistema);
      expect(leidas.contraste, Contraste.normal);
      expect(leidas.tamanoTexto, TamanoTexto.normal);
      expect(leidas.modoDaltonismo, ModoDaltonismo.normal);
    });

    test('un valor fuera del catálogo cae en el más cercano', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_apar_tema': 'neon',
        'quickbite_apar_tamano': 'enorme',
        'quickbite_apar_daltonismo': 'protanopea',
      });
      final prefs = await SharedPreferences.getInstance();

      final leidas = await AparienciaRepository(prefs).read();

      expect(leidas.tema, TemaApp.sistema);
      expect(leidas.tamanoTexto, TamanoTexto.normal);
      expect(leidas.modoDaltonismo, ModoDaltonismo.normal);
    });

    test('restablecer borra solo las claves de apariencia', () async {
      await preferences.setString('quickbite_search_history', 'burger');
      final repo = AparienciaRepository(preferences);
      await repo.save(
        const PreferenciasApariencia(tema: TemaApp.oscuro),
      );

      await repo.clear();

      expect(await repo.read(), const PreferenciasApariencia());
      expect(preferences.getString('quickbite_search_history'), 'burger');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:quickbite_mobile/src/features/profile/data/idioma_repository.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_idioma.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdiomaRepository (07.1 SCR-PROF-10)', () {
    test('sin nada guardado usa español, DD/MM/AAAA y 24 horas', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = IdiomaRepository(await SharedPreferences.getInstance());

      expect(
        await repo.read(),
        const PreferenciasIdioma(
          idioma: IdiomaApp.espanol,
          formatoFecha: FormatoFecha.diaMesAno,
          formatoHora: FormatoHora.veinticuatro,
        ),
      );
    });

    test('guarda y recupera los tres formatos', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = IdiomaRepository(await SharedPreferences.getInstance());

      await repo.save(
        const PreferenciasIdioma(
          formatoFecha: FormatoFecha.anoMesDia,
          formatoHora: FormatoHora.doce,
        ),
      );

      expect(
        await repo.read(),
        const PreferenciasIdioma(
          idioma: IdiomaApp.espanol,
          formatoFecha: FormatoFecha.anoMesDia,
          formatoHora: FormatoHora.doce,
        ),
      );
    });

    test('el idioma se queda en español aunque se guarde otra cosa', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_idioma_app': 'english',
      });
      final repo = IdiomaRepository(await SharedPreferences.getInstance());

      expect((await repo.read()).idioma, IdiomaApp.espanol);
    });

    test('un valor fuera del catálogo cae en el más cercano', () async {
      SharedPreferences.setMockInitialValues({
        'quickbite_idioma_fecha': 'japon',
        'quickbite_idioma_hora': 9,
      });
      final repo = IdiomaRepository(await SharedPreferences.getInstance());

      final leidas = await repo.read();

      expect(leidas.formatoFecha, FormatoFecha.diaMesAno);
      expect(leidas.formatoHora, FormatoHora.veinticuatro);
    });
  });

  group('Formatos regionales (07.1 SCR-PROF-10)', () {
    final fecha = DateTime(2026, 9, 28, 21, 5);

    test('cada formato de fecha produce el orden que promete', () {
      expect(
        FormatoFecha.diaMesAno.patron,
        'dd/MM/yyyy',
        reason: 'es el formato de España',
      );
      expect(FormatoFecha.mesDiaAno.patron, 'MM/dd/yyyy');
      expect(FormatoFecha.anoMesDia.patron, 'yyyy-MM-dd');
    });

    test('el formato elegido se aplica a la fecha', () {
      expect(FormatoFecha.anoMesDia.formatear(fecha), '2026-09-28');
      expect(FormatoFecha.diaMesAno.formatear(fecha), '28/09/2026');
    });

    test('el formato de hora decide el reloj de 12 o de 24 horas', () {
      expect(FormatoHora.veinticuatro.formatear(fecha), '21:05');
      expect(FormatoHora.doce.formatear(fecha), '09:05 PM');
    });

    test('formatear con intl usa el patrón del enum', () {
      expect(
        DateFormat(FormatoFecha.anoMesDia.patron).format(fecha),
        '2026-09-28',
      );
    });
  });
}

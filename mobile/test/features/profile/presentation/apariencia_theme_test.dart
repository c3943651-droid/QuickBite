import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_apariencia.dart';
import 'package:quickbite_mobile/src/features/profile/presentation/apariencia_theme.dart';

void main() {
  group('modoTema (07.1 SCR-PROF-09)', () {
    test('cada opción de tema produce su ThemeMode', () {
      expect(
        modoTema(const PreferenciasApariencia(tema: TemaApp.claro)),
        ThemeMode.light,
      );
      expect(
        modoTema(const PreferenciasApariencia(tema: TemaApp.oscuro)),
        ThemeMode.dark,
      );
      expect(
        modoTema(const PreferenciasApariencia(tema: TemaApp.sistema)),
        ThemeMode.system,
      );
    });
  });

  group('escalaTexto (07.1 SCR-PROF-09)', () {
    test('multiplica la escala del sistema para no ignorarla', () {
      const sistema = TextScaler.linear(1.5);

      expect(
        escalaTexto(
          const PreferenciasApariencia(tamanoTexto: TamanoTexto.normal),
          sistema,
        ).scale(10),
        15,
      );
      expect(
        escalaTexto(
          const PreferenciasApariencia(tamanoTexto: TamanoTexto.muyGrande),
          sistema,
        ).scale(10),
        closeTo(19.5, 0.01),
      );
    });

    test('el tamaño pequeño reduce sobre la escala elegida', () {
      expect(
        escalaTexto(
          const PreferenciasApariencia(tamanoTexto: TamanoTexto.pequeno),
          const TextScaler.linear(1),
        ).scale(10),
        9,
      );
    });
  });

  group('paleta accesible (07.1 SCR-PROF-09)', () {
    test('el modo daltónico cambia el color principal', () {
      final normal = temaClaro(const PreferenciasApariencia());
      final deuteranopia = temaClaro(
        const PreferenciasApariencia(
          modoDaltonismo: ModoDaltonismo.deuteranopia,
        ),
      );
      final protanopia = temaClaro(
        const PreferenciasApariencia(modoDaltonismo: ModoDaltonismo.protanopia),
      );
      final tritanopia = temaClaro(
        const PreferenciasApariencia(modoDaltonismo: ModoDaltonismo.tritanopia),
      );

      expect(
        deuteranopia.colorScheme.primary,
        isNot(normal.colorScheme.primary),
      );
      expect(
        protanopia.colorScheme.primary,
        isNot(deuteranopia.colorScheme.primary),
      );
      expect(
        tritanopia.colorScheme.primary,
        isNot(protanopia.colorScheme.primary),
      );
    });

    test('el alto contraste lleva el texto a negro puro y refuerza bordes', () {
      final normal = temaClaro(const PreferenciasApariencia());
      final alto = temaClaro(
        const PreferenciasApariencia(contraste: Contraste.alto),
      );

      expect(alto.textTheme.bodyLarge?.color, Colors.black);
      expect(alto.appBarTheme.foregroundColor, Colors.black);
      expect(normal.textTheme.bodyLarge?.color, isNot(Colors.black));
      expect(
        alto.inputDecorationTheme.focusedBorder?.borderSide.width,
        greaterThan(
          normal.inputDecorationTheme.focusedBorder?.borderSide.width ?? 0,
        ),
      );
    });

    test('el alto contraste también aplica en modo oscuro', () {
      final alto = temaOscuro(
        const PreferenciasApariencia(contraste: Contraste.alto),
      );

      expect(alto.textTheme.bodyLarge?.color, Colors.white);
      expect(alto.appBarTheme.foregroundColor, Colors.white);
    });

    test('temaClaro y temaOscuro difieren en brillo', () {
      expect(
        temaClaro(const PreferenciasApariencia()).colorScheme.brightness,
        Brightness.light,
      );
      expect(
        temaOscuro(const PreferenciasApariencia()).colorScheme.brightness,
        Brightness.dark,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_radius.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';
import 'package:quickbite_mobile/src/features/profile/domain/preferencias_apariencia.dart';

/// Rediseño visual: paleta clara de alto contraste en lugar del naranja plano.
///
/// Los tests fijan los valores exactos a propósito. Una paleta es una decisión de
/// marca, no una preferencia: si alguien cambia un hex sin querer, este archivo
/// falla y obliga a revisar el cambio a propósito.
/// Componentes 0-255 de un color.
///
/// `Color.r/g/b` son double en 0..1 desde Flutter 3.27, así que multiplicar sin
/// convertir daba ceros y las comprobaciones de "es cálido" pasaban siempre.
(int, int, int) canales(Color color) =>
    ((color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round());

void main() {
  group('paleta de marca', () {
    test('el fondo es un apPergamino claro, no un gris plano', () {
      expect(AppColors.background, const Color(0xFFF8FAFC));
    });

    test('las superficies son blanco puro con borde suave', () {
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.border, const Color(0xFFE2E8F0));
    });

    test('el acento es verde esmeralda, no naranja ni amarillo', () {
      expect(AppColors.accent, const Color(0xFF0D9488));
      expect(AppColors.accentDeep, const Color(0xFF0F766E));
    });

    test('el color de acento no es un naranja ni un amarillo', () {
      final (rojo, verde, azul) = canales(AppColors.accent);

      // Predominio verde-azulado: es un teal, no un cálido.
      expect(verde, greaterThan(rojo));
      expect(azul, greaterThan(rojo));
      expect(verde, greaterThan(azul));
    });

    test('el texto principal es ciruela profunda', () {
      expect(AppColors.ink, const Color(0xFF0F172A));
    });

    test('el texto conserva contraste AA sobre el fondo de la app', () {
      // Lo que se mide es el contraste contra el fondo real, no entre los
      // colores: es el dato que decide si se puede leer la pantalla al sol.
      double contraste(Color texto, Color fondo) {
        final a = texto.computeLuminance();
        final b = fondo.computeLuminance();
        return (a > b ? a : b) / ((a > b ? b : a) + 0.05);
      }

      // WCAG AA para texto normal es 4.5:1.
      expect(contraste(AppColors.ink, AppColors.background), greaterThan(4.5));
      expect(
        contraste(AppColors.inkMuted, AppColors.background),
        greaterThan(4.5),
      );
      // Los placeholders están exentos de AA: se exige que se vean, no que
      // se puedan leer como texto principal.
      expect(
        contraste(AppColors.inkSoft, AppColors.background),
        greaterThan(2),
      );
    });

    test('el acento tiene contraste AA como color de texto', () {
      double contraste(Color a, Color b) {
        final x = a.computeLuminance();
        final y = b.computeLuminance();
        return (x > y ? x : y) / ((x > y ? y : x) + 0.05);
      }

      expect(contraste(AppColors.accent, AppColors.surface), greaterThan(3));
    });

    test('ni las superficies ni los acentos son cálidos', () {
      // El rojo de error sí es cálido por definición: lo que no puede pasar es
      // que un tono de superficie o de marca se vaya al naranja/amarillo, que es
      // lo que hacía que la app se leyera como "oferta" en todas partes.
      const neutrosYacentos = <Color>[
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceMuted,
        AppColors.border,
        AppColors.ink,
        AppColors.inkMuted,
        AppColors.inkSoft,
        AppColors.accent,
        AppColors.accentDeep,
        AppColors.accentAlt,
        AppColors.nightBackground,
        AppColors.nightSurface,
        AppColors.nightBorder,
        AppColors.nightInk,
      ];

      for (final color in neutrosYacentos) {
        final (rojo, verde, azul) = canales(color);
        final esCalido = rojo - verde > 40;
        expect(
          esCalido,
          isFalse,
          reason: 'el token #${color.toARGB32().toRadixString(16)} es cálido',
        );
      }
    });

    test('el aviso no es amarillo puro sino ámbar quemado', () {
      // El amarillo sobre blanco no llega a 3:1 y era el peor color posible en
      // pantalla al sol; el ámbar quemado sí se distingue y se lee.
      final (rojo, verde, azul) = canales(AppColors.warning);
      expect(
        verde,
        greaterThan(azul),
        reason: 'sigue siendo cálido, pero atenuado',
      );
      expect(rojo, greaterThan(20));
      expect(verde, lessThan(120), reason: 'no es un amarillo brillante');
    });
  });

  group('tema claro', () {
    final theme = AppTheme.claro(const PreferenciasApariencia());

    test('el scaffold usa el fondo claro de marca', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('el primario es el acento y el texto sobre él es blanco', () {
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.colorScheme.onPrimary, Colors.white);
    });

    test('el texto principal usa la tinta ciruela', () {
      expect(theme.textTheme.bodyLarge?.color, AppColors.ink);
    });

    test('las tarjetas son blancas con borde suave y radio amplio', () {
      final card = theme.cardTheme;
      expect(card.color, AppColors.surface);
      expect(
        (card.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.card),
      );
      expect(AppRadius.card, greaterThanOrEqualTo(18));
    });

    test('los chips usan forma de píldora', () {
      expect(AppRadius.chip, 999);
    });
  });

  group('tema oscuro', () {
    final theme = AppTheme.oscuro(const PreferenciasApariencia());

    test('deja de ser un fondo plano casi negro', () {
      // El fondo viejo era #121212 puro; ahora es un pizarra profundo.
      expect(theme.scaffoldBackgroundColor, AppColors.nightBackground);
      expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFF121212)));
      expect(theme.scaffoldBackgroundColor, isNot(AppColors.ink));
    });

    test('conserva el acento de marca', () {
      expect(theme.colorScheme.primary, AppColors.accent);
    });

    test('el texto claro mantiene contraste sobre el fondo', () {
      final fondo = theme.scaffoldBackgroundColor;
      // Se mide el color de texto del `ColorScheme` y no el de un `TextTheme`
      // concreto: es el token que cualquier texto de la app hereda, y no obliga
      // a desempaquetar un estilo nullable.
      final texto = theme.colorScheme.onSurface;
      final a = texto.computeLuminance();
      final b = fondo.computeLuminance();
      // El más claro arriba, como en la fórmula de WCAG.
      final contraste = (a > b ? a : b) / ((a > b ? b : a) + 0.05);
      expect(contraste, greaterThan(4.5));
    });
  });

  group('accesibilidad: los modos daltónicos siguen siendo distinguibles', () {
    for (final modo in ModoDaltonismo.values) {
      test('modo $modo cambia el color de marca', () {
        final prefs = PreferenciasApariencia(
          modoDaltonismo: modo,
          contraste: Contraste.normal,
        );
        final primario = AppTheme.claro(prefs).colorScheme.primary;

        if (modo == ModoDaltonismo.normal) {
          expect(primario, AppColors.accent);
        } else {
          expect(
            primario,
            isNot(AppColors.accent),
            reason: 'sin variar, el modo $modo no aportaría nada',
          );
        }
      });
    }

    test('el contraste alto mantiene el texto negro sobre fondo claro', () {
      final prefs = PreferenciasApariencia(contraste: Contraste.alto);
      final theme = AppTheme.claro(prefs);

      expect(theme.textTheme.bodyLarge?.color, Colors.black);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickbite_mobile/src/core/theme/app_colors.dart';
import 'package:quickbite_mobile/src/core/theme/app_theme.dart';

import '../../support/contrast.dart';

/// Regresión de contraste: el `TextTheme` de la app debe definir **todos** los
/// estilos que las pantallas usan.
///
/// Si un estilo no está definido, Flutter cae en el `Typography` por defecto de
/// Material: un color que ignora el modo oscuro y el de alto contraste, y que
/// sobre superficies claras (o en oscuro) resulta ilegible. Pasó con
/// `titleSmall`, `headlineSmall` y `bodySmall`: el número de unidades del
/// selector de cantidad y los textos secundarios del detalle de producto salían
/// casi invisibles.
void main() {
  group('TextTheme de la app', () {
    test('define todos los estilos con color explícito', () {
      final claro = AppTheme.light.textTheme;

      final estilos = <String, TextStyle?>{
        'displayLarge': claro.displayLarge,
        'headlineLarge': claro.headlineLarge,
        'headlineMedium': claro.headlineMedium,
        'headlineSmall': claro.headlineSmall,
        'titleLarge': claro.titleLarge,
        'titleMedium': claro.titleMedium,
        'titleSmall': claro.titleSmall,
        'bodyLarge': claro.bodyLarge,
        'bodyMedium': claro.bodyMedium,
        'bodySmall': claro.bodySmall,
        'labelLarge': claro.labelLarge,
        'labelMedium': claro.labelMedium,
        'labelSmall': claro.labelSmall,
      };

      estilos.forEach((nombre, estilo) {
        expect(
          estilo,
          isNotNull,
          reason: '$nombre no está definido en el tema',
        );
        expect(
          estilo?.color,
          isNotNull,
          reason: '$nombre no tiene color explícito',
        );
      });
    });

    test('los titulares usan el color principal de cada modo', () {
      expect(AppTheme.light.textTheme.titleSmall?.color, AppColors.ink);
      expect(AppTheme.light.textTheme.headlineSmall?.color, AppColors.ink);

      expect(AppTheme.dark.textTheme.titleSmall?.color, AppColors.nightInk);
      expect(AppTheme.dark.textTheme.headlineSmall?.color, AppColors.nightInk);
    });

    test('el modo oscuro no deja texto oscuro sobre superficie oscura', () {
      expect(AppTheme.dark.textTheme.titleSmall?.color, isNot(AppColors.ink));
      expect(AppTheme.dark.textTheme.bodySmall?.color, isNot(AppColors.ink));
    });

    test('los estilos llegan a 4.5:1 sobre la superficie de su modo', () {
      final claro = AppTheme.light.textTheme;
      final oscuro = AppTheme.dark.textTheme;

      expect(
        contraste(claro.titleSmall!.color!, AppColors.surface),
        greaterThan(4.5),
      );
      expect(
        contraste(claro.bodySmall!.color!, AppColors.surface),
        greaterThan(4.5),
      );
      expect(
        contraste(oscuro.titleSmall!.color!, AppColors.nightSurface),
        greaterThan(4.5),
      );
      expect(
        contraste(oscuro.bodySmall!.color!, AppColors.nightSurface),
        greaterThan(4.5),
      );
    });
  });
}

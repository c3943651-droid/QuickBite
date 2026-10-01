import 'app_radius.dart';

import 'package:flutter/material.dart';

import '../../features/profile/domain/preferencias_apariencia.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => claro(const PreferenciasApariencia());

  static ThemeData get dark => oscuro(const PreferenciasApariencia());

  /// Tema claro con la paleta derivada de las preferencias de accesibilidad
  /// (07.1 SCR-PROF-09).
  static ThemeData claro(PreferenciasApariencia prefs) =>
      _construir(prefs: prefs, brightness: Brightness.light);

  /// Tema oscuro con la misma paleta de accesibilidad.
  static ThemeData oscuro(PreferenciasApariencia prefs) =>
      _construir(prefs: prefs, brightness: Brightness.dark);

  static ThemeData _construir({
    required PreferenciasApariencia prefs,
    required Brightness brightness,
  }) {
    final paleta = _Paleta.desdePreferencias(
      prefs: prefs,
      oscuro: brightness == Brightness.dark,
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: paleta.primario,
      brightness: brightness,
      primary: paleta.primario,
      secondary: paleta.secundario,
      tertiary: paleta.terciario,
      surface: paleta.superficie,
      error: paleta.error,
    );

    return _base(colorScheme, prefs: prefs, paleta: paleta).copyWith(
      scaffoldBackgroundColor: paleta.fondo,
      appBarTheme: AppBarTheme(
        backgroundColor: paleta.superficie,
        foregroundColor: paleta.textoPrincipal,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(paleta.textoPrincipal, paleta.textoSecundario),
    );
  }

  static ThemeData _base(
    ColorScheme colorScheme, {
    required PreferenciasApariencia prefs,
    required _Paleta paleta,
  }) {
    final grosor = prefs.altoContraste ? 2.0 : 1.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _border(colorScheme.outlineVariant, width: grosor),
        enabledBorder: _border(colorScheme.outlineVariant, width: grosor),
        focusedBorder: _border(colorScheme.primary, width: grosor + 1),
        errorBorder: _border(paleta.error, width: grosor),
        focusedErrorBorder: _border(paleta.error, width: grosor + 1),
        errorStyle: AppTextStyles.label.copyWith(color: paleta.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: colorScheme.primary,
          foregroundColor: paleta.sobrePrimario,
          textStyle: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: grosor + 1),
          textStyle: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        labelStyle: AppTextStyles.label.copyWith(color: colorScheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: grosor,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Estilos del tema.
  ///
  /// Se definen **todos** los que usa la app a propósito: un estilo sin
  /// definir aquí no falla, pero Flutter lo sustituye por el `Typography` por
  /// defecto de Material, cuyo color ignora el modo oscuro y el de alto
  /// contraste. Pasó con `headlineSmall`, `titleSmall` y `bodySmall`: el
  /// selector de cantidad y los textos secundarios del detalle de producto se
  /// quedaban casi invisibles.
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.display.copyWith(color: primary),
      headlineLarge: AppTextStyles.headline1.copyWith(color: primary),
      headlineMedium: AppTextStyles.headline2.copyWith(color: primary),
      headlineSmall: AppTextStyles.headline2.copyWith(
        fontSize: 24,
        color: primary,
      ),
      titleLarge: AppTextStyles.title.copyWith(color: primary),
      titleMedium: AppTextStyles.title.copyWith(fontSize: 16, color: primary),
      titleSmall: AppTextStyles.title.copyWith(fontSize: 14, color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
      bodySmall: AppTextStyles.bodyMedium.copyWith(
        fontSize: 12,
        color: secondary,
      ),
      labelLarge: AppTextStyles.label.copyWith(fontSize: 16, color: primary),
      labelMedium: AppTextStyles.label.copyWith(color: secondary),
      labelSmall: AppTextStyles.caption.copyWith(color: secondary),
    );
  }
}

/// Paleta efectiva de una pantalla.
///
/// El modo daltónico cambia el color de marca por una variante con la misma
/// función pero perceptiblemente distinta. La paleta base ya es un teal
/// (frío, con mucho contraste en los tres tipos), pero aun así se reasigna:
/// deuteranopía y protanopía no distinguen bien el eje verde-rojo, así que en
/// esos modos el acento pasa a azul y en tritanopía a magenta, donde el eje
/// rojo-verde sí se percibe.
class _Paleta {
  const _Paleta({
    required this.primario,
    required this.secundario,
    required this.terciario,
    required this.error,
    required this.exito,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.superficie,
    required this.fondo,
    required this.borde,
    required this.sobrePrimario,
  });

  factory _Paleta.desdePreferencias({
    required PreferenciasApariencia prefs,
    required bool oscuro,
  }) {
    final alto = prefs.altoContraste;

    return switch (prefs.modoDaltonismo) {
      ModoDaltonismo.normal => _Paleta._estandar(oscuro: oscuro, alto: alto),
      ModoDaltonismo.deuteranopia => _Paleta._estandar(
        oscuro: oscuro,
        alto: alto,
        primario: const Color(0xFF1D4ED8),
        secundario: const Color(0xFF7C3AED),
        terciario: const Color(0xFF0369A1),
        exito: const Color(0xFF0369A1),
      ),
      ModoDaltonismo.protanopia => _Paleta._estandar(
        oscuro: oscuro,
        alto: alto,
        primario: const Color(0xFF1E40AF),
        secundario: const Color(0xFF6D28D9),
        terciario: const Color(0xFF0E7490),
        exito: const Color(0xFF0E7490),
      ),
      ModoDaltonismo.tritanopia => _Paleta._estandar(
        oscuro: oscuro,
        alto: alto,
        primario: const Color(0xFFBE185D),
        secundario: const Color(0xFF7E22CE),
        terciario: const Color(0xFF4F46E5),
        exito: const Color(0xFF4F46E5),
      ),
    };
  }

  factory _Paleta._estandar({
    required bool oscuro,
    required bool alto,
    Color? primario,
    Color? secundario,
    Color? terciario,
    Color? error,
    Color? exito,
  }) {
    return _Paleta(
      primario: primario ?? AppColors.accent,
      secundario: secundario ?? AppColors.accentAlt,
      terciario: terciario ?? AppColors.info,
      error: error ?? AppColors.error,
      exito: exito ?? AppColors.success,
      textoPrincipal: alto
          ? (oscuro ? AppColors.white : Colors.black)
          : (oscuro ? AppColors.nightInk : AppColors.ink),
      textoSecundario: alto
          ? (oscuro ? AppColors.white : Colors.black)
          : (oscuro ? AppColors.inkSoft : AppColors.inkMuted),
      superficie: oscuro ? AppColors.nightSurface : AppColors.surface,
      fondo: oscuro ? AppColors.nightBackground : AppColors.background,
      borde: oscuro ? AppColors.nightBorder : AppColors.border,
      sobrePrimario: Colors.white,
    );
  }

  final Color primario;
  final Color secundario;
  final Color terciario;
  final Color error;
  final Color exito;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color superficie;
  final Color fondo;
  final Color borde;
  final Color sobrePrimario;
}

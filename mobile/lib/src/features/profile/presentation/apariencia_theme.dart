import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/preferencias_apariencia.dart';

/// Traducción de las preferencias de apariencia a valores de `MaterialApp`
/// (07.1 SCR-PROF-09).
///
/// Son funciones puras a propósito: `app.dart` solo las monta y así el efecto
/// real de cada preferencia se puede probar sin levantar la app entera.

/// Tema claro/oscuro que decide [MaterialApp.themeMode].
ThemeData temaClaro(PreferenciasApariencia prefs) => AppTheme.claro(prefs);

/// @see temaClaro
ThemeData temaOscuro(PreferenciasApariencia prefs) => AppTheme.oscuro(prefs);

/// "Sistema" se traduce a [ThemeMode.system] para que la app siga al sistema
/// operativo en vez de congelar el tema que haya ahora mismo.
ThemeMode modoTema(PreferenciasApariencia prefs) => switch (prefs.tema) {
  TemaApp.claro => ThemeMode.light,
  TemaApp.oscuro => ThemeMode.dark,
  TemaApp.sistema => ThemeMode.system,
};

/// Escala de texto de la app.
///
/// Multiplica la que ya venga del sistema en lugar de sustituirla: un usuario
/// con la fuente agrandada en los ajustes del teléfono la quiere grande dentro de
/// la app, y la opción de QuickBite solo ajusta el punto de partida.
TextScaler escalaTexto(PreferenciasApariencia prefs, TextScaler delSistema) =>
    TextScaler.linear(delSistema.scale(prefs.tamanoTexto.factor));

/// Las animaciones se desactivan si el sistema ya las desactivó o si el usuario
/// lo pidió aquí: `disableAnimations` solo desactiva, nunca reactiva.
bool sinAnimaciones(PreferenciasApariencia prefs, bool delSistema) =>
    prefs.reducirAnimaciones || delSistema;

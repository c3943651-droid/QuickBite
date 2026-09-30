import 'package:equatable/equatable.dart';

/// Preferencias de apariencia (07.1 SCR-PROF-09).
///
/// La pantalla no tiene endpoints ("todo local"), así que el estado vive en el
/// dispositivo ([AparienciaRepository] lo persiste en `SharedPreferences`) y se
/// aplica al instante desde `app.dart`.
///
/// La paleta de alto contraste y de los modos daltónicos es una decisión
/// provisional: 09 §4 solo fija la paleta base, así que aquí se derivan de ella
/// reasignando los tonos que no se distinguen con cada tipo de daltonismo. Ver
/// "Accesibilidad" en 09.
enum TemaApp {
  claro('Claro'),
  oscuro('Oscuro'),
  sistema('Sistema');

  const TemaApp(this.etiqueta);

  final String etiqueta;
}

enum TamanoTexto {
  pequeno('Pequeño', 0.9),
  normal('Normal', 1),
  grande('Grande', 1.15),
  muyGrande('Muy grande', 1.3);

  const TamanoTexto(this.etiqueta, this.factor);

  final String etiqueta;

  /// Se multiplica sobre la escala que ya venga del sistema, nunca la reemplaza:
  /// quien agranda la fuente en los ajustes del teléfono la quiere grande también
  /// dentro de la app.
  final double factor;
}

enum Contraste { normal, alto }

enum ModoDaltonismo {
  normal('Normal'),
  deuteranopia('Deuteranopía'),
  protanopia('Protanopía'),
  tritanopia('Tritanopía');

  const ModoDaltonismo(this.etiqueta);

  final String etiqueta;
}

class PreferenciasApariencia extends Equatable {
  const PreferenciasApariencia({
    this.tema = TemaApp.sistema,
    this.tamanoTexto = TamanoTexto.normal,
    this.contraste = Contraste.normal,
    this.reducirAnimaciones = false,
    this.modoDaltonismo = ModoDaltonismo.normal,
  });

  final TemaApp tema;
  final TamanoTexto tamanoTexto;
  final Contraste contraste;
  final bool reducirAnimaciones;
  final ModoDaltonismo modoDaltonismo;

  bool get altoContraste => contraste == Contraste.alto;

  PreferenciasApariencia conTema(TemaApp value) => copiar(tema: value);

  PreferenciasApariencia conTamanoTexto(TamanoTexto value) =>
      copiar(tamanoTexto: value);

  PreferenciasApariencia conContraste(Contraste value) =>
      copiar(contraste: value);

  PreferenciasApariencia conReducirAnimaciones(bool value) =>
      copiar(reducirAnimaciones: value);

  PreferenciasApariencia conModoDaltonismo(ModoDaltonismo value) =>
      copiar(modoDaltonismo: value);

  PreferenciasApariencia copiar({
    TemaApp? tema,
    TamanoTexto? tamanoTexto,
    Contraste? contraste,
    bool? reducirAnimaciones,
    ModoDaltonismo? modoDaltonismo,
  }) => PreferenciasApariencia(
    tema: tema ?? this.tema,
    tamanoTexto: tamanoTexto ?? this.tamanoTexto,
    contraste: contraste ?? this.contraste,
    reducirAnimaciones: reducirAnimaciones ?? this.reducirAnimaciones,
    modoDaltonismo: modoDaltonismo ?? this.modoDaltonismo,
  );

  @override
  List<Object?> get props => [
    tema,
    tamanoTexto,
    contraste,
    reducirAnimaciones,
    modoDaltonismo,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Idiomas disponibles. En v1.0 solo español (07.1 SCR-PROF-10): el enum crece
/// cuando haya traducción real, no antes.
enum IdiomaApp {
  espanol('Español');

  const IdiomaApp(this.etiqueta);

  final String etiqueta;
}

/// Orden de los tres formatos de fecha que ofrece la pantalla.
enum FormatoFecha {
  diaMesAno('DD/MM/AAAA', 'dd/MM/yyyy'),
  mesDiaAno('MM/DD/AAAA', 'MM/dd/yyyy'),
  anoMesDia('AAAA-MM-DD', 'yyyy-MM-dd');

  const FormatoFecha(this.etiqueta, this.patron);

  /// Lo que ve el usuario.
  final String etiqueta;

  /// Patrón de [DateFormat] equivalente.
  final String patron;

  String formatear(DateTime fecha) => DateFormat(patron).format(fecha);
}

/// Reloj de 12 o 24 horas. Los dos son de 12 horas con `hh:mm a` en el primer
/// caso, para que el formato sea el que el usuario reconoce.
enum FormatoHora {
  veinticuatro('24 horas'),
  doce('12 horas');

  const FormatoHora(this.etiqueta);

  final String etiqueta;

  String formatear(DateTime hora) => switch (this) {
    FormatoHora.veinticuatro => DateFormat('HH:mm').format(hora),
    FormatoHora.doce => DateFormat('hh:mm a').format(hora),
  };
}

/// Idioma y formatos regionales (07.1 SCR-PROF-10).
///
/// Todo local: no depende de la cuenta ni de la red, así que se resuelve junto
/// con las preferencias de apariencia.
class PreferenciasIdioma extends Equatable {
  const PreferenciasIdioma({
    this.idioma = IdiomaApp.espanol,
    this.formatoFecha = FormatoFecha.diaMesAno,
    this.formatoHora = FormatoHora.veinticuatro,
  });

  final IdiomaApp idioma;
  final FormatoFecha formatoFecha;
  final FormatoHora formatoHora;

  PreferenciasIdioma conFormatoFecha(FormatoFecha formato) =>
      PreferenciasIdioma(
        idioma: idioma,
        formatoFecha: formato,
        formatoHora: formatoHora,
      );

  PreferenciasIdioma conFormatoHora(FormatoHora formato) => PreferenciasIdioma(
    idioma: idioma,
    formatoFecha: formatoFecha,
    formatoHora: formato,
  );

  /// Fecha y hora con los formatos elegidos, que es como los pintan las
  /// pantallas (sesiones, pedidos).
  String formatearFechaHora(DateTime momento) =>
      '${formatoFecha.formatear(momento)} · ${formatoHora.formatear(momento)}';

  @override
  List<Object?> get props => [idioma, formatoFecha, formatoHora];
}

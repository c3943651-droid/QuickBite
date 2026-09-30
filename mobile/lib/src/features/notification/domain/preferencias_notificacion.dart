import 'package:equatable/equatable.dart';

import '../../../core/polling/polling_controller.dart';
import 'notification_entities.dart';

/// Preferencias in-app de notificaciones (07.1 SCR-PROF-08).
///
/// 07.1 deja esta pantalla explícitamente sin endpoints ("todo local"), así que
/// el estado vive en el dispositivo y [PreferenciasRepository] lo persiste.
/// Los cinco tipos, el sonido y la vibración controlan si la app muestra o
/// entrega la notificación; la frecuencia acota el polling del seguimiento
/// (05#D-01, 07 §8.6) y por eso se normaliza al catálogo permitido.
class PreferenciasNotificacion extends Equatable {
  const PreferenciasNotificacion({
    this.pedidoNuevo = true,
    this.cambioEstado = true,
    this.asignacion = true,
    this.sistema = true,
    this.recordatorio = true,
    this.sonido = true,
    this.vibracion = true,
    this.intervaloActualizacion = FrecuenciaPolling.porDefecto,
  });

  final bool pedidoNuevo;
  final bool cambioEstado;
  final bool asignacion;
  final bool sistema;
  final bool recordatorio;
  final bool sonido;
  final bool vibracion;
  final Duration intervaloActualizacion;

  /// ¿La app debe entregar este tipo de notificación?
  bool permite(TipoNotificacion tipo) => switch (tipo) {
    TipoNotificacion.pedidoNuevo => pedidoNuevo,
    TipoNotificacion.cambioEstado => cambioEstado,
    TipoNotificacion.asignacion => asignacion,
    TipoNotificacion.sistema => sistema,
    TipoNotificacion.recordatorio => recordatorio,
  };

  PreferenciasNotificacion actualizarTipo(TipoNotificacion tipo, bool activo) =>
      switch (tipo) {
        TipoNotificacion.pedidoNuevo => copiar(pedidoNuevo: activo),
        TipoNotificacion.cambioEstado => copiar(cambioEstado: activo),
        TipoNotificacion.asignacion => copiar(asignacion: activo),
        TipoNotificacion.sistema => copiar(sistema: activo),
        TipoNotificacion.recordatorio => copiar(recordatorio: activo),
      };

  PreferenciasNotificacion conSonido(bool activo) => copiar(sonido: activo);

  PreferenciasNotificacion conVibracion(bool activo) =>
      copiar(vibracion: activo);

  PreferenciasNotificacion conIntervalo(Duration intervalo) =>
      copiar(intervaloActualizacion: FrecuenciaPolling.normalizar(intervalo));

  PreferenciasNotificacion copiar({
    bool? pedidoNuevo,
    bool? cambioEstado,
    bool? asignacion,
    bool? sistema,
    bool? recordatorio,
    bool? sonido,
    bool? vibracion,
    Duration? intervaloActualizacion,
  }) => PreferenciasNotificacion(
    pedidoNuevo: pedidoNuevo ?? this.pedidoNuevo,
    cambioEstado: cambioEstado ?? this.cambioEstado,
    asignacion: asignacion ?? this.asignacion,
    sistema: sistema ?? this.sistema,
    recordatorio: recordatorio ?? this.recordatorio,
    sonido: sonido ?? this.sonido,
    vibracion: vibracion ?? this.vibracion,
    intervaloActualizacion:
        intervaloActualizacion ?? this.intervaloActualizacion,
  );

  @override
  List<Object?> get props => [
    pedidoNuevo,
    cambioEstado,
    asignacion,
    sistema,
    recordatorio,
    sonido,
    vibracion,
    intervaloActualizacion,
  ];
}

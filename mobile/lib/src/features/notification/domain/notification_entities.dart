import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipos de notificación. El backend los serializa como enteros, por eso el
/// dominio trabaja con `api` numérico y no con el nombre del enum.
enum TipoNotificacion {
  pedidoNuevo(1, 'Pedido recibido', Icons.receipt_long),
  cambioEstado(2, 'Cambio de estado', Icons.local_shipping),
  asignacion(3, 'Repartidor asignado', Icons.delivery_dining),
  sistema(4, 'Aviso del sistema', Icons.info_outline),
  recordatorio(5, 'Recordatorio', Icons.alarm);

  const TipoNotificacion(this.api, this.etiqueta, this.icono);

  final int api;
  final String etiqueta;
  final IconData icono;

  static TipoNotificacion desdeApi(int api) => switch (api) {
    1 => TipoNotificacion.pedidoNuevo,
    2 => TipoNotificacion.cambioEstado,
    3 => TipoNotificacion.asignacion,
    4 => TipoNotificacion.sistema,
    5 => TipoNotificacion.recordatorio,
    _ => TipoNotificacion.sistema,
  };

  /// `true` para los tipos ligados al ciclo de vida de un pedido.
  bool get esPedido =>
      this == pedidoNuevo || this == cambioEstado || this == asignacion;
}

class Notificacion extends Equatable {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.creadoEn,
    this.pedidoId,
    this.leido = false,
    this.leidoEn,
  });

  final String id;
  final TipoNotificacion tipo;
  final String titulo;
  final String mensaje;
  final String? pedidoId;
  final bool leido;
  final DateTime? leidoEn;
  final DateTime creadoEn;

  bool get tienePedido => pedidoId != null && pedidoId!.isNotEmpty;

  Notificacion copyWith({bool? leido, DateTime? leidoEn}) => Notificacion(
    id: id,
    tipo: tipo,
    titulo: titulo,
    mensaje: mensaje,
    pedidoId: pedidoId,
    leido: leido ?? this.leido,
    leidoEn: leidoEn ?? this.leidoEn,
    creadoEn: creadoEn,
  );

  @override
  List<Object?> get props => [
    id,
    tipo,
    titulo,
    mensaje,
    pedidoId,
    leido,
    leidoEn,
  ];
}

/// Filtros de la bandeja (07.1 SCR-NOTIF-01).
enum FiltroNotificacion {
  todas('Todas'),
  noLeidas('No leídas'),
  pedidos('Pedidos'),
  sistema('Sistema');

  const FiltroNotificacion(this.etiqueta);

  final String etiqueta;

  bool incluye(Notificacion notificacion) => switch (this) {
    FiltroNotificacion.todas => true,
    FiltroNotificacion.noLeidas => !notificacion.leido,
    FiltroNotificacion.pedidos => notificacion.tipo.esPedido,
    FiltroNotificacion.sistema => !notificacion.tipo.esPedido,
  };
}

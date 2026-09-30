import 'package:equatable/equatable.dart';

/// Estado de disponibilidad del repartidor (07.1 SCR-DEL-07).
///
/// Los valores son los de `DeliveryPersonStatus` del backend, no un enum propio:
/// la app manda el número en `PUT /delivery/availability` y lo recibe en la
/// respuesta, así que un enum local solo añadiría una traducción que se podría
/// desincronizar del servidor.
enum DeliveryPersonStatus {
  disponible(1, 'Disponible'),
  ocupado(2, 'Ocupado'),
  inactivo(3, 'Inactivo');

  const DeliveryPersonStatus(this.api, this.etiqueta);

  final int api;
  final String etiqueta;

  static DeliveryPersonStatus fromApi(Object? value) {
    final numero = switch (value) {
      final int v => v,
      final String v => int.tryParse(v),
      _ => null,
    };
    return values.firstWhere(
      (estado) => estado.api == numero,
      orElse: () => inactivo,
    );
  }
}

/// Respuesta de `PUT /delivery/availability`.
///
/// `tieneEntregaActiva` viene del servidor para que la pantalla muestre el aviso
/// de SCR-DEL-07 sin tener que deducirlo del pedido en curso.
class Disponibilidad extends Equatable {
  const Disponibilidad({
    required this.estado,
    required this.tieneEntregaActiva,
  });

  final DeliveryPersonStatus estado;
  final bool tieneEntregaActiva;

  bool get estaDisponible => estado == DeliveryPersonStatus.disponible;

  @override
  List<Object?> get props => [estado, tieneEntregaActiva];
}

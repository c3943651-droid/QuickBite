import 'package:equatable/equatable.dart';

/// Métricas del repartidor (07.1 SCR-DEL-06), servidas por `GET /delivery/stats`.
///
/// Los nombres vienen del `DeliveryPersonStatsDto` real del backend, que no
/// coinciden con los de `04 §11.6`; se sigue al código porque es el que
/// responde. El identificador del repartidor no se expone: siempre es el de la
/// sesión y ninguna pantalla lo necesita.
class EstadisticasRepartidor extends Equatable {
  const EstadisticasRepartidor({
    required this.entregasTotales,
    required this.entregasDelMes,
    required this.tiempoPromedioEntregaMinutos,
    required this.pedidosAsignados,
    required this.cancelaciones,
  });

  /// Un repartidor que todavía no entregó nada ve ceros, no una pantalla vacía.
  const EstadisticasRepartidor.vacias()
    : entregasTotales = 0,
      entregasDelMes = 0,
      tiempoPromedioEntregaMinutos = 0,
      pedidosAsignados = 0,
      cancelaciones = 0;

  final int entregasTotales;
  final int entregasDelMes;
  final double tiempoPromedioEntregaMinutos;
  final int pedidosAsignados;
  final int cancelaciones;

  bool get estaVacia => entregasTotales == 0;

  @override
  List<Object?> get props => [
    entregasTotales,
    entregasDelMes,
    tiempoPromedioEntregaMinutos,
    pedidosAsignados,
    cancelaciones,
  ];
}

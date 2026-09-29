import 'disponibilidad.dart';
import 'estadisticas_repartidor.dart';
import 'pedido_entrega.dart';

/// Datos del repartidor contra la API (07.1 SCR-DEL-01 a SCR-DEL-06).
///
/// Todos los pedidos comparten el mismo `OrderResponse`, tanto los disponibles
/// como el activo y el historial, así que las tres listas se leen igual.
abstract interface class DeliveryRepository {
  /// Pedidos listos y sin repartidor asignado. La pantalla los refresca cada
  /// 30 s (07.3, decisión 2) mientras la app está en primer plano.
  Future<List<PedidoEntrega>> pedidosDisponibles();

  /// Toma un pedido: 204 en el backend, el repartidor pasa a ocupado.
  Future<void> aceptar(String pedidoId);

  /// Entrega en curso, o `null` si el repartidor está libre. El backend
  /// devuelve una lista; la UI trabaja siempre con una sola.
  Future<PedidoEntrega?> entregaActiva();

  /// Marca la entrega como completada: 204 en el backend.
  Future<void> completar(String pedidoId);

  /// Entregas ya realizadas, del pedido más reciente al más antiguo.
  Future<List<PedidoEntrega>> historialEntregas();

  Future<EstadisticasRepartidor> estadisticas();

  /// Estado de disponibilidad del repartidor autenticado.
  Future<Disponibilidad> disponibilidad();

  /// Cambia el estado y devuelve el resultante. Falla con
  /// `BusinessRuleException` si tiene una entrega en curso y pide estar
  /// disponible.
  Future<Disponibilidad> cambiarDisponibilidad(DeliveryPersonStatus estado);
}

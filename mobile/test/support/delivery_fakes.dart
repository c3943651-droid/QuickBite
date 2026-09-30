import 'dart:async';

import 'package:quickbite_mobile/src/features/delivery/domain/delivery_repository.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/disponibilidad.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/estadisticas_repartidor.dart';
import 'package:quickbite_mobile/src/features/delivery/domain/pedido_entrega.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';

/// Datos de repartidor en memoria para probar las pantallas sin HTTP.
///
/// Reproduce el ciclo que impone el backend: aceptar mueve el pedido de
/// disponibles a la entrega en curso y completarlo lo devuelve en el
/// historial. Así la pantalla de entrega activa no necesita inventario real.
class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository({List<PedidoEntrega> disponibles = const []})
    : disponibles = [...disponibles];

  /// Pedidos que `GET /delivery/available` devuelve.
  List<PedidoEntrega> disponibles;

  /// Entrega en curso; `null` si el repartidor está libre.
  PedidoEntrega? activa;

  /// Entregas completadas, de la más reciente a la más antigua.
  List<PedidoEntrega> historial = [];

  /// Métricas de `GET /delivery/stats`.
  EstadisticasRepartidor stats = const EstadisticasRepartidor.vacias();

  /// Si se asigna, toda llamada de red lanza este error.
  Object? error;

  /// Si se asigna, `aceptar` lanza este error (p. ej. ya no disponible).
  Object? aceptarError;

  /// Si se asigna, `completar` lanza este error.
  Object? completarError;

  /// Estado de disponibilidad con el que responde `GET /delivery/availability`.
  DeliveryPersonStatus estado = DeliveryPersonStatus.inactivo;

  /// Si el repartidor tiene una entrega en curso (SCR-DEL-07).
  bool tieneEntregaActiva = false;

  /// Si se asigna, `disponibilidad()` lanza este error.
  Object? estadoError;

  /// Si se asigna, `cambiarDisponibilidad` lanza este error (p. ej. la regla de
  /// negocio de "no disponible con entrega activa").
  Object? cambiarDisponibilidadError;

  /// Estados pedidos, en orden.
  final List<DeliveryPersonStatus> cambiosDisponibilidad = [];

  /// Ids de los pedidos aceptados, en orden.
  final List<String> aceptados = [];

  /// Ids de los pedidos completados, en orden.
  final List<String> completados = [];

  /// Veces que se pidieron los disponibles: el polling se cuenta aquí.
  int consultasDisponibles = 0;

  /// Veces que se pidió la entrega activa: el polling de 07.3 cuenta aquí.
  int consultasActivas = 0;

  /// Si está asignado, la consulta espera a que se complete antes de
  /// responder; sirve para observar la petición en vuelo en los tests de widget.
  Completer<void>? gate;

  @override
  Future<List<PedidoEntrega>> pedidosDisponibles() async {
    consultasDisponibles++;
    await _resolverGate();
    final failure = error;
    if (failure != null) throw failure;
    return List.unmodifiable(disponibles);
  }

  @override
  Future<void> aceptar(String pedidoId) async {
    final failure = aceptarError ?? error;
    if (failure != null) throw failure;
    aceptados.add(pedidoId);
    final encontrado = disponibles.where((p) => p.id == pedidoId);
    if (encontrado.isEmpty) {
      throw StateError('El pedido $pedidoId no estaba disponible.');
    }
    disponibles = disponibles.where((p) => p.id != pedidoId).toList();
    activa = PedidoEntrega(
      id: encontrado.first.id,
      numeroPedido: encontrado.first.numeroPedido,
      estado: EstadoPedido.enCamino.api,
      total: encontrado.first.total,
      creadoEn: encontrado.first.creadoEn,
    );
  }

  @override
  Future<PedidoEntrega?> entregaActiva() async {
    consultasActivas++;
    await _resolverGate();
    final failure = error;
    if (failure != null) throw failure;
    return activa;
  }

  @override
  Future<void> completar(String pedidoId) async {
    final failure = completarError ?? error;
    if (failure != null) throw failure;
    completados.add(pedidoId);
    final enCurso = activa;
    if (enCurso == null || enCurso.id != pedidoId) {
      throw StateError('No hay una entrega en curso con id $pedidoId.');
    }
    activa = null;
    historial = [
      PedidoEntrega(
        id: enCurso.id,
        numeroPedido: enCurso.numeroPedido,
        estado: EstadoPedido.entregado.api,
        total: enCurso.total,
        creadoEn: enCurso.creadoEn,
      ),
      ...historial,
    ];
  }

  @override
  Future<List<PedidoEntrega>> historialEntregas() async {
    final failure = error;
    if (failure != null) throw failure;
    return List.unmodifiable(historial);
  }

  @override
  Future<Disponibilidad> disponibilidad() async {
    final failure = estadoError ?? error;
    if (failure != null) throw failure;
    return Disponibilidad(
      estado: estado,
      tieneEntregaActiva: tieneEntregaActiva,
    );
  }

  @override
  Future<Disponibilidad> cambiarDisponibilidad(
    DeliveryPersonStatus nuevo,
  ) async {
    cambiosDisponibilidad.add(nuevo);
    final failure = cambiarDisponibilidadError ?? error;
    if (failure != null) throw failure;
    estado = nuevo;
    return Disponibilidad(
      estado: estado,
      tieneEntregaActiva: tieneEntregaActiva,
    );
  }

  @override
  Future<EstadisticasRepartidor> estadisticas() async {
    final failure = error;
    if (failure != null) throw failure;
    return stats;
  }

  Future<void> _resolverGate() async => await gate?.future;
}

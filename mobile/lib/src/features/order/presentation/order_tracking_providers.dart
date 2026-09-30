import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/core/polling/polling_controller.dart';
import 'package:quickbite_mobile/src/core/widgets/status_timeline.dart';
import 'package:quickbite_mobile/src/features/notification/presentation/preferencias_providers.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_entities.dart';
import 'package:quickbite_mobile/src/features/order/domain/order_repository.dart';

import 'checkout_providers.dart';

/// Frecuencia del polling de seguimiento (07.1 SCR-PROF-08, 05#D-01).
///
/// Sale de la preferencia local de la persona usuaria; mientras esa preferencia
/// aún no se ha leído de disco se usa el valor por defecto, y el rango permitido
/// lo acota [FrecuenciaPolling.normalizar]. El `select` hace que el seguimiento
/// solo se recomponga cuando la duración cambia de verdad, no cuando termina la
/// lectura inicial.
final intervaloPollingProvider = Provider<Duration>((ref) {
  final intervalo = ref.watch(
    preferenciasNotificacionProvider.select(
      (preferencias) => preferencias.value?.intervaloActualizacion,
    ),
  );
  return intervalo ?? FrecuenciaPolling.porDefecto;
});

/// Seguimiento de un pedido (07.1 SCR-ORDER-01).
///
/// El detalle se trae una sola vez al abrir la pantalla; lo que se repite cada
/// 10 s es `GET /orders/{id}/status`, que es más liviano y es exactamente lo que
/// cambia durante el recorrido.
final orderTrackingProvider =
    NotifierProvider.family<OrderTrackingNotifier, OrderTrackingState, String>(
      OrderTrackingNotifier.new,
    );

class OrderTrackingState {
  const OrderTrackingState({
    this.pedido,
    this.cargando = true,
    this.consultando = false,
    this.pollingActivo = false,
    this.pausadoPorErrores = false,
    this.actualizadoEn,
    this.error,
  });

  final Order? pedido;

  /// Primera carga de la pantalla: aún no hay nada que pintar.
  final bool cargando;

  /// Hay una consulta en vuelo (alimenta el `PollingIndicator`).
  final bool consultando;

  /// El reloj del polling está corriendo.
  final bool pollingActivo;

  final bool pausadoPorErrores;

  /// Hora del último cambio de estado que confirmó la API.
  final DateTime? actualizadoEn;

  /// Error de la última acción (carga, polling o cancelación).
  final String? error;

  EstadoPedido get estado => pedido?.estadoPedido ?? EstadoPedido.pendiente;

  /// 07.1 SCR-ORDER-01 — cancelar solo mientras está pendiente o confirmado.
  bool get puedeCancelar => pedido != null && estado.esCancelable;

  /// El indicador de actualización solo se muestra si el polling sigue vivo:
  /// en un estado final no hay nada que actualizar (07 §8.6).
  bool get mostrarIndicador => consultando && pollingActivo;

  OrderTrackingState copyWith({
    Order? pedido,
    bool? cargando,
    bool? consultando,
    bool? pollingActivo,
    bool? pausadoPorErrores,
    DateTime? actualizadoEn,
    String? error,
    bool limpiarError = false,
  }) {
    return OrderTrackingState(
      pedido: pedido ?? this.pedido,
      cargando: cargando ?? this.cargando,
      consultando: consultando ?? this.consultando,
      pollingActivo: pollingActivo ?? this.pollingActivo,
      pausadoPorErrores: pausadoPorErrores ?? this.pausadoPorErrores,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class OrderTrackingNotifier extends Notifier<OrderTrackingState> {
  OrderTrackingNotifier(this.orderId);

  final String orderId;

  late final PollingController polling;

  @override
  OrderTrackingState build() {
    polling = PollingController(
      intervalo: ref.read(intervaloPollingProvider),
      onTick: _consultarEstado,
      onError: (error, _) =>
          state = state.copyWith(consultando: false, error: _mensaje(error)),
      onPausa: () => state = state.copyWith(
        consultando: false,
        pollingActivo: false,
        pausadoPorErrores: true,
        error: 'Sin conexión. Revisa tu red para seguir el pedido.',
      ),
    );
    ref.onDispose(polling.stop);
    // 07 §8.6: el polling arranca al entrar a la pantalla. Se deja visible
    // desde el principio para que no dependa de que la pantalla recuerde
    // calling [iniciar].
    polling.start();
    unawaited(_cargarDetalle());
    return const OrderTrackingState(pollingActivo: true);
  }

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  /// La pantalla se enfocó o la app pasó a segundo plano (07 §8.6).
  void setVisible(bool visible) {
    polling.setVisible(visible);
    state = state.copyWith(pollingActivo: polling.isRunning);
  }

  /// Al salir de la pantalla.
  void detener() {
    polling.stop();
    state = state.copyWith(pollingActivo: false);
  }

  /// "Reintentar" tras una pausa por errores.
  void reintentar() {
    polling.reanudar();
    state = state.copyWith(
      pollingActivo: true,
      pausadoPorErrores: false,
      limpiarError: true,
    );
  }

  /// El error ya se mostró en un snackbar: se limpia para no duplicarlo en el
  /// aviso inline de la pantalla.
  void limpiarError() {
    state = state.copyWith(limpiarError: true);
  }

  Future<void> recargar() => _cargarDetalle();

  Future<void> _cargarDetalle() async {
    try {
      final pedido = await _repo.getOrder(orderId);
      if (!ref.mounted) return;
      state = state.copyWith(
        pedido: pedido,
        cargando: false,
        limpiarError: true,
        pollingActivo: polling.isRunning,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        cargando: false,
        pollingActivo: false,
        error: _mensaje(error),
      );
    }
  }

  /// Un tick del polling: `GET /orders/{id}/status`. Devolver `false` para el
  /// motor significa "estado final": deja de consultar.
  Future<bool> _consultarEstado() async {
    state = state.copyWith(consultando: true, pollingActivo: true);
    try {
      final actual = await _repo.getStatus(orderId);
      if (!ref.mounted) return actual.estado.esActivo;
      state = state.copyWith(
        pedido: state.pedido?.copyWith(estado: actual.estado.api),
        consultando: false,
        pollingActivo: actual.estado.esActivo,
        actualizadoEn: actual.actualizadoEn.toLocal(),
        limpiarError: true,
      );
      return actual.estado.esActivo;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(consultando: false, error: _mensaje(error));
      }
      rethrow;
    }
  }

  /// 07.1 SCR-ORDER-02 — cancelación. Devuelve `false` si la API la rechazó.
  Future<bool> cancelar(String? motivo) async {
    state = state.copyWith(consultando: true, limpiarError: true);
    try {
      await _repo.cancelOrder(orderId, motivo: motivo);
      if (!ref.mounted) return true;
      state = state.copyWith(
        pedido: state.pedido?.copyWith(estado: EstadoPedido.cancelado.api),
        consultando: false,
        pollingActivo: false,
      );
      polling.stop();
      return true;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(consultando: false, error: _mensaje(error));
      }
      return false;
    }
  }

  static String _mensaje(Object error) => switch (error) {
    AppException(:final userMessage) => userMessage,
    _ => 'No pudimos actualizar el pedido. Intenta de nuevo.',
  };
}

/// Traduce el estado del backend a los pasos de `StatusTimeline` (H0.3).
///
/// `GET /orders/{id}/status` solo trae el estado actual y la hora del último
/// cambio, no un historial: por eso el timestamp se muestra solo en el paso
/// actual, y un pedido cancelado deja la línea en gris porque la API no dice en
/// qué punto se canceló.
List<TimelineStep> pasosTimeline(
  EstadoPedido estado, {
  DateTime? actualizadoEn,
}) {
  final indice = estado.indiceEnLinea;
  return [
    for (var i = 0; i < EstadoPedido.linea.length; i++)
      TimelineStep(
        label: _etiquetas[i],
        icon: _iconos[i],
        timestamp: (actualizadoEn != null && i == indice)
            ? _hora(actualizadoEn)
            : null,
        state: switch (estado) {
          EstadoPedido.entregado => TimelineStepState.completed,
          EstadoPedido.cancelado => TimelineStepState.pending,
          _ when i < indice => TimelineStepState.completed,
          _ when i == indice => TimelineStepState.current,
          _ => TimelineStepState.pending,
        },
      ),
  ];
}

const _etiquetas = [
  'Pendiente',
  'Confirmado',
  'Preparando',
  'Listo',
  'En camino',
  'Entregado',
];

const _iconos = [
  Icons.receipt_long,
  Icons.check_circle_outline,
  Icons.soup_kitchen,
  Icons.shopping_bag_outlined,
  Icons.delivery_dining,
  Icons.home_work,
];

String _hora(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

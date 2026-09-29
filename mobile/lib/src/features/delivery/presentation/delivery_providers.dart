import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/polling/polling_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/delivery_remote_data_source.dart';
import '../data/delivery_repository_impl.dart';
import '../domain/delivery_repository.dart';
import '../domain/disponibilidad.dart';
import '../domain/estadisticas_repartidor.dart';
import '../domain/pedido_entrega.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>(
  (ref) => DeliveryRepositoryImpl(
    DeliveryRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);

/// Frecuencia del polling de pedidos disponibles (07.1 SCR-DEL-01, 05#D-01).
///
/// Son 30 s fijos y no la preferencia de SCR-PROF-08: esa preferencia es para el
/// seguimiento del cliente, y aquí el riesgo es que otro repartidor se lleve el
/// pedido, no que se demore la actualización.
const intervaloPollingDisponibles = Duration(seconds: 30);

/// Pedidos listos para tomar (07.1 SCR-DEL-01).
///
/// Es un notifier y no un `FutureProvider` porque la pantalla refresca sola cada
/// 30 s y necesita distinguir "primera carga" de "actualizando en segundo plano":
/// solo la primera muestra skeleton, la segunda no debe vaciar la lista.
final pedidosDisponiblesProvider =
    NotifierProvider.autoDispose<
      PedidosDisponiblesNotifier,
      PedidosDisponiblesState
    >(PedidosDisponiblesNotifier.new);

@immutable
class PedidosDisponiblesState {
  const PedidosDisponiblesState({
    this.pedidos = const [],
    this.cargando = true,
    this.consultando = false,
    this.pollingActivo = false,
    this.pausadoPorErrores = false,
    this.aceptando = false,
    this.accionError,
    this.error,
  });

  final List<PedidoEntrega> pedidos;

  /// Primera carga: no hay nada que pintar todavía.
  final bool cargando;

  /// Consulta en vuelo, alimenta el [PollingIndicator].
  final bool consultando;

  final bool pollingActivo;

  /// El polling se agotó reintentando tras errores (07 §8.6).
  final bool pausadoPorErrores;

  /// Hay un `aceptar` en vuelo: bloquea el botón de la fila.
  final bool aceptando;

  /// Fallo de la última acción (aceptar), no de la carga.
  final String? accionError;

  /// Fallo de la carga o del polling.
  final String? error;

  /// 07.1 SCR-DEL-01 — vacío de verdad, no "todavía no ha llegado nada".
  bool get vacio => !cargando && pedidos.isEmpty && error == null;

  bool get mostrarIndicador => consultando && pollingActivo;

  PedidosDisponiblesState copyWith({
    List<PedidoEntrega>? pedidos,
    bool? cargando,
    bool? consultando,
    bool? pollingActivo,
    bool? pausadoPorErrores,
    bool? aceptando,
    String? accionError,
    String? error,
    bool limpiarAccionError = false,
    bool limpiarError = false,
  }) {
    return PedidosDisponiblesState(
      pedidos: pedidos ?? this.pedidos,
      cargando: cargando ?? this.cargando,
      consultando: consultando ?? this.consultando,
      pollingActivo: pollingActivo ?? this.pollingActivo,
      pausadoPorErrores: pausadoPorErrores ?? this.pausadoPorErrores,
      aceptando: aceptando ?? this.aceptando,
      accionError: limpiarAccionError
          ? null
          : (accionError ?? this.accionError),
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class PedidosDisponiblesNotifier extends Notifier<PedidosDisponiblesState> {
  /// No es `final`: un provider `autoDispose` reconstruye su notifier cuando
  /// vuelve a tener escuchas, y `build()` tiene que poder crear otro motor.
  late PollingController _polling;

  @override
  PedidosDisponiblesState build() {
    _polling = PollingController(
      intervalo: intervaloPollingDisponibles,
      onTick: _consultar,
      onError: (error, _) => _fallo(error, consulta: true),
      onPausa: () => state = state.copyWith(
        consultando: false,
        pollingActivo: false,
        pausadoPorErrores: true,
        error: 'Sin conexión. Revisa tu red para ver nuevos pedidos.',
      ),
    );
    ref.onDispose(_polling.stop);
    // 07 §8.6: el polling arranca al entrar a la pantalla. La primera consulta
    // la hace el propio motor, así que no hace falta pedir los datos aparte.
    _polling.start();
    return const PedidosDisponiblesState();
  }

  /// El motor se expone para que la pantalla lo detenga en `dispose`, igual que
  /// hace la de seguimiento de pedidos.
  PollingController get polling => _polling;

  DeliveryRepository get _repo => ref.read(deliveryRepositoryProvider);

  /// La pantalla recuperó el foco o la app volvió de segundo plano.
  void setVisible(bool visible) {
    _polling.setVisible(visible);
    state = state.copyWith(pollingActivo: _polling.isRunning);
  }

  /// 07.1 SCR-DEL-01 — "Refrescar" fuerza consulta inmediata sin tocar el reloj.
  Future<void> refrescar() => _cargar();

  /// "Reintentar" tras una pausa por errores.
  void reintentar() {
    _polling.reanudar();
    state = state.copyWith(
      pollingActivo: true,
      pausadoPorErrores: false,
      cargando: true,
      limpiarError: true,
    );
    unawaited(_cargar());
  }

  /// 07.1 SCR-DEL-02 — tomar el pedido (05#D-03). Devuelve `true` si la API lo
  /// asignó; los cuatro mensajes de validación de negocio llegan como
  /// [AppException] y se muestran sin transformar.
  Future<bool> aceptar(String pedidoId) async {
    state = state.copyWith(aceptando: true, limpiarAccionError: true);
    try {
      await _repo.aceptar(pedidoId);
      if (!ref.mounted) return true;
      state = state.copyWith(aceptando: false);
      // El pedido deja de estar disponible: se quita de la lista sin volver a
      // preguntar, que es lo que quiere ver quien acaba de tomarlo.
      state = state.copyWith(
        pedidos: state.pedidos
            .where((p) => p.id != pedidoId)
            .toList(growable: false),
      );
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(aceptando: false, accionError: mensaje(error));
      }
      return false;
    }
  }

  void limpiarAccionError() => state = state.copyWith(limpiarAccionError: true);

  Future<void> _cargar() async {
    state = state.copyWith(
      consultando: true,
      cargando: true,
      limpiarError: true,
    );
    try {
      final pedidos = await _repo.pedidosDisponibles();
      if (!ref.mounted) return;
      state = state.copyWith(
        pedidos: pedidos,
        cargando: false,
        consultando: false,
        pollingActivo: _polling.isRunning,
        limpiarError: true,
      );
    } on Object catch (error) {
      _fallo(error, consulta: false);
    }
  }

  /// Un tick del polling. La lista de disponibles nunca es un estado final: si
  /// no hay pedidos, sigue preguntando.
  Future<bool> _consultar() async {
    state = state.copyWith(consultando: true, pollingActivo: true);
    try {
      final pedidos = await _repo.pedidosDisponibles();
      if (!ref.mounted) return true;
      state = state.copyWith(
        pedidos: pedidos,
        cargando: false,
        consultando: false,
        pollingActivo: _polling.isRunning,
        limpiarError: true,
      );
      return true;
    } on Object catch (error) {
      _fallo(error, consulta: true);
      rethrow;
    }
  }

  void _fallo(Object error, {required bool consulta}) {
    if (!ref.mounted) return;
    state = state.copyWith(
      cargando: false,
      consultando: false,
      pollingActivo: consulta ? _polling.isRunning : false,
      error: mensaje(error),
    );
  }
}

/// Entrega en curso (07.1 SCR-DEL-03).
///
/// `autoDispose` porque la respuesta es la de "ahora mismo": al salir de la
/// pestaña y volver, el repartidor tiene que ver si el backend le quitó el
/// pedido, no lo que vio hace un rato.
final entregaActivaProvider = FutureProvider.autoDispose<PedidoEntrega?>((ref) {
  return ref.watch(deliveryRepositoryProvider).entregaActiva();
}, retry: (retryCount, error) => null);

/// Entregas ya realizadas (07.1 SCR-DEL-04).
final historialEntregasProvider =
    FutureProvider.autoDispose<List<PedidoEntrega>>(
      (ref) => ref.read(deliveryRepositoryProvider).historialEntregas(),
      retry: (retryCount, error) => null,
    );

/// Métricas personales (07.1 SCR-DEL-06).
final estadisticasRepartidorProvider =
    FutureProvider.autoDispose<EstadisticasRepartidor>(
      (ref) => ref.read(deliveryRepositoryProvider).estadisticas(),
      retry: (retryCount, error) => null,
    );

/// Acciones de la entrega en curso: completar (07.1 SCR-DEL-03).
///
/// Es un notifier aparte y no un método de la pantalla porque la confirmación y
/// la llamada se disparan desde el botón y el resultado tiene que poder
/// invalidar la lista de disponibles, el historial y las estadísticas.
final entregaAccionesProvider =
    NotifierProvider.autoDispose<EntregaAccionesNotifier, EntregaAccionesState>(
      EntregaAccionesNotifier.new,
    );

@immutable
class EntregaAccionesState {
  const EntregaAccionesState({this.completando = false, this.error});

  final bool completando;
  final String? error;

  EntregaAccionesState copyWith({
    bool? completando,
    String? error,
    bool limpiarError = false,
  }) {
    return EntregaAccionesState(
      completando: completando ?? this.completando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class EntregaAccionesNotifier extends Notifier<EntregaAccionesState> {
  @override
  EntregaAccionesState build() => const EntregaAccionesState();

  /// 07.1 SCR-DEL-03 — "Marcar como entregado".
  Future<bool> completar(String pedidoId) async {
    state = state.copyWith(completando: true, limpiarError: true);
    try {
      await ref.read(deliveryRepositoryProvider).completar(pedidoId);
      if (!ref.mounted) return true;
      state = const EntregaAccionesState();
      // El backend es la única fuente de verdad: se revalida todo lo que
      // depende de que esa entrega ya no está en curso.
      ref.invalidate(entregaActivaProvider);
      ref.invalidate(historialEntregasProvider);
      ref.invalidate(estadisticasRepartidorProvider);
      ref.invalidate(pedidosDisponiblesProvider);
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = EntregaAccionesState(error: mensaje(error));
      }
      return false;
    }
  }

  void limpiarError() => state = state.copyWith(limpiarError: true);
}

/// Mensaje para la persona repartidora.
///
/// Los errores de negocio del backend (409 "ya asignado", 403) llegan con su
/// texto y se muestran tal cual: son la explicación de por qué no se pudo
/// aceptar, y un texto genérico los volvería inútiles.
String mensaje(Object error) => switch (error) {
  AppException(:final userMessage) => userMessage,
  _ => 'No pudimos conectar con QuickBite. Intenta de nuevo.',
};

/// Estado de disponibilidad del repartidor (07.1 SCR-DEL-07).
final disponibilidadProvider = FutureProvider.autoDispose<Disponibilidad>((
  ref,
) {
  return ref.read(deliveryRepositoryProvider).disponibilidad();
}, retry: (retryCount, error) => null);

/// Cambio de disponibilidad (07.1 SCR-DEL-07).
///
/// Devuelve `true` si el backend aceptó el estado. El servidor devuelve el
/// estado resultante, así que no hace falta suponer nada tras la llamada.
final cambiarDisponibilidadProvider =
    NotifierProvider.autoDispose<
      CambiarDisponibilidadNotifier,
      EstadoCambioDisponibilidad
    >(CambiarDisponibilidadNotifier.new);

@immutable
class EstadoCambioDisponibilidad {
  const EstadoCambioDisponibilidad({this.cambiando = false, this.error});

  final bool cambiando;
  final String? error;

  EstadoCambioDisponibilidad copyWith({
    bool? cambiando,
    String? error,
    bool limpiarError = false,
  }) {
    return EstadoCambioDisponibilidad(
      cambiando: cambiando ?? this.cambiando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

class CambiarDisponibilidadNotifier
    extends Notifier<EstadoCambioDisponibilidad> {
  @override
  EstadoCambioDisponibilidad build() => const EstadoCambioDisponibilidad();

  Future<bool> cambiar(bool disponible) async {
    final nuevo = disponible
        ? DeliveryPersonStatus.disponible
        : DeliveryPersonStatus.inactivo;
    state = state.copyWith(cambiando: true, limpiarError: true);
    try {
      final resultado = await ref
          .read(deliveryRepositoryProvider)
          .cambiarDisponibilidad(nuevo);
      if (!ref.mounted) return true;
      state = const EstadoCambioDisponibilidad();
      // Se invalida para que la pantalla se pinte con lo que dice el servidor y
      // no con lo que la app suponía.
      ref.invalidate(disponibilidadProvider);
      ref.invalidate(pedidosDisponiblesProvider);
      return resultado.estado == nuevo;
    } on Object catch (error) {
      if (ref.mounted) {
        state = EstadoCambioDisponibilidad(error: mensaje(error));
      }
      // El servidor puede haberlo rechazado: la pantalla vuelve a leer el estado
      // real, que sigue siendo el anterior.
      ref.invalidate(disponibilidadProvider);
      return false;
    }
  }

  void limpiarError() => state = state.copyWith(limpiarError: true);
}

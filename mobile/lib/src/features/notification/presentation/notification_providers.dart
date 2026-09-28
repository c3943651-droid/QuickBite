import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbite_mobile/src/core/error/app_exception.dart';
import 'package:quickbite_mobile/src/features/auth/presentation/auth_providers.dart';
import 'package:quickbite_mobile/src/features/notification/data/notification_remote_data_source.dart';
import 'package:quickbite_mobile/src/features/notification/data/notification_repository_impl.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    NotificationRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

/// Bandeja de notificaciones (07.1 SCR-NOTIF-01). Sin `retry`: riverpod 3
/// reintenta solo y dejaría la pantalla en "cargando" sin mostrar el error.
final notificationsProvider = FutureProvider.autoDispose<List<Notificacion>>(
  (ref) => ref.watch(notificationRepositoryProvider).listNotifications(),
  retry: (retryCount, error) => null,
);

final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, FiltroNotificacion>(
      NotificationFilterNotifier.new,
    );

class NotificationFilterNotifier extends Notifier<FiltroNotificacion> {
  @override
  FiltroNotificacion build() => FiltroNotificacion.todas;

  void seleccionar(FiltroNotificacion filtro) => state = filtro;
}

/// La bandeja del filtro activo, de la más reciente a la más antigua.
final notificationsFiltradasProvider = Provider<List<Notificacion>>((ref) {
  final notificaciones =
      ref.watch(notificationsProvider).value ?? const <Notificacion>[];
  final filtro = ref.watch(notificationFilterProvider);
  final filtradas = notificaciones.where(filtro.incluye).toList(growable: false)
    ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
  return filtradas;
});

/// Badge de la bandeja: cuántas quedan sin leer.
final notificationsNoLeidasProvider = Provider<int>((ref) {
  final notificaciones =
      ref.watch(notificationsProvider).value ?? const <Notificacion>[];
  return notificaciones.where((n) => !n.leido).length;
});

@immutable
class NotificationAccionesState {
  const NotificationAccionesState({this.marcando = false, this.error});

  final bool marcando;
  final String? error;

  bool get hayError => error != null;
}

/// Marcar leída / marcar todas (07.1 SCR-NOTIF-01). La bandeja se invalida tras
/// cada operación: el backend es la única fuente de verdad.
final notificationAccionesProvider =
    NotifierProvider<NotificationAccionesNotifier, NotificationAccionesState>(
      NotificationAccionesNotifier.new,
    );

class NotificationAccionesNotifier extends Notifier<NotificationAccionesState> {
  @override
  NotificationAccionesState build() => const NotificationAccionesState();

  Future<bool> marcarLeida(String id) =>
      _ejecutar(() => ref.read(notificationRepositoryProvider).marcarLeida(id));

  Future<bool> marcarTodasLeidas() => _ejecutar(
    () => ref.read(notificationRepositoryProvider).marcarTodasLeidas(),
  );

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    state = const NotificationAccionesState(marcando: true);
    try {
      await accion();
      ref.invalidate(notificationsProvider);
      state = const NotificationAccionesState();
      return true;
    } on Object catch (error) {
      state = NotificationAccionesState(error: _mensaje(error));
      return false;
    }
  }

  static String _mensaje(Object error) => switch (error) {
    AppException(:final userMessage) => userMessage,
    _ => 'No pudimos actualizar tus notificaciones.',
  };
}

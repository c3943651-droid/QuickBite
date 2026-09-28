import 'package:quickbite_mobile/src/features/notification/domain/notification_entities.dart';
import 'package:quickbite_mobile/src/features/notification/domain/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<Notificacion> notificaciones = const []})
    : notificaciones = List.of(notificaciones);

  List<Notificacion> notificaciones;

  /// Si se asigna, `listNotifications` lanza este error.
  Object? listError;

  /// Si se asigna, `marcarLeida` y `marcarTodasLeidas` lanzan este error.
  Object? marcarError;

  /// Ids marcados como leídos, en orden.
  final List<String> leidas = [];

  /// Veces que se pidió marcar todas como leídas.
  int todasMarcadas = 0;

  @override
  Future<List<Notificacion>> listNotifications({
    bool soloNoLeidas = false,
  }) async {
    final error = listError;
    if (error != null) throw error;
    return List<Notificacion>.unmodifiable(
      soloNoLeidas ? notificaciones.where((n) => !n.leido) : notificaciones,
    );
  }

  @override
  Future<void> marcarLeida(String id) async {
    final error = marcarError;
    if (error != null) throw error;
    leidas.add(id);
    notificaciones = [
      for (final n in notificaciones)
        if (n.id == id) n.copyWith(leido: true) else n,
    ];
  }

  @override
  Future<void> marcarTodasLeidas() async {
    final error = marcarError;
    if (error != null) throw error;
    todasMarcadas++;
    notificaciones = [for (final n in notificaciones) n.copyWith(leido: true)];
  }
}

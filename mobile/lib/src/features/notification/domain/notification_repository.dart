import 'notification_entities.dart';

abstract interface class NotificationRepository {
  Future<List<Notificacion>> listNotifications({bool soloNoLeidas = false});

  Future<void> marcarLeida(String id);

  Future<void> marcarTodasLeidas();
}

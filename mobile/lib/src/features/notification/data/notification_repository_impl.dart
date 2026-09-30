import '../domain/notification_entities.dart';
import '../domain/notification_repository.dart';
import 'dtos/notification_dtos.dart';
import 'notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<List<Notificacion>> listNotifications({
    bool soloNoLeidas = false,
  }) async {
    final dtos = await _remote.getNotifications(unreadOnly: soloNoLeidas);
    return dtos.map(_toNotificacion).toList(growable: false);
  }

  @override
  Future<void> marcarLeida(String id) => _remote.markAsRead(id);

  @override
  Future<void> marcarTodasLeidas() => _remote.markAllAsRead();

  Notificacion _toNotificacion(NotificationDto dto) => Notificacion(
    id: dto.id,
    tipo: TipoNotificacion.desdeApi(dto.tipo),
    titulo: dto.titulo,
    mensaje: dto.mensaje,
    pedidoId: dto.pedidoId,
    leido: dto.leido,
    leidoEn: dto.leidoEn,
    creadoEn: dto.creadoEn.toLocal(),
  );
}

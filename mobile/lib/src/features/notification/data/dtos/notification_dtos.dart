import 'package:json_annotation/json_annotation.dart';

part 'notification_dtos.g.dart';

/// La API no tiene un DTO de respuesta documentado: devuelve la entidad
/// `Notification` con `tipo` numérico (ver `NotificationType` en el backend).
@JsonSerializable()
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leido,
    required this.creadoEn,
    this.pedidoId,
    this.leidoEn,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);

  final String id;
  final int tipo;
  final String titulo;
  final String mensaje;
  final String? pedidoId;
  final bool leido;
  final DateTime? leidoEn;
  final DateTime creadoEn;
}

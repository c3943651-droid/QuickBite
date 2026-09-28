// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    NotificationDto(
      id: json['id'] as String,
      tipo: (json['tipo'] as num).toInt(),
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      leido: json['leido'] as bool,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      pedidoId: json['pedidoId'] as String?,
      leidoEn: json['leidoEn'] == null
          ? null
          : DateTime.parse(json['leidoEn'] as String),
    );

Map<String, dynamic> _$NotificationDtoToJson(NotificationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': instance.tipo,
      'titulo': instance.titulo,
      'mensaje': instance.mensaje,
      'pedidoId': instance.pedidoId,
      'leido': instance.leido,
      'leidoEn': instance.leidoEn?.toIso8601String(),
      'creadoEn': instance.creadoEn.toIso8601String(),
    };

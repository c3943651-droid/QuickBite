import 'package:json_annotation/json_annotation.dart';

part 'api_error_response.g.dart';

@JsonSerializable()
class ApiErrorResponse {
  const ApiErrorResponse({
    this.timestamp,
    this.status,
    this.error,
    this.message,
    this.path,
    this.details,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);

  final DateTime? timestamp;
  final int? status;
  final String? error;
  final String? message;
  final String? path;
  final Map<String, List<String>>? details;
}

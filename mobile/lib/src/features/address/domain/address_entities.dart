import 'package:equatable/equatable.dart';

/// Dirección de entrega del cliente (04 §4.4). El backend usa snake_case y la
/// app nombres en camelCase, así que el mapeo vive en el datasource.
class Address extends Equatable {
  const Address({
    required this.id,
    required this.calle,
    required this.ciudad,
    this.alias,
    this.numero,
    this.referencia,
    this.latitud,
    this.longitud,
    this.esPredeterminada = false,
    this.creadoEn,
  });

  final String id;
  final String calle;
  final String ciudad;
  final String? alias;
  final String? numero;
  final String? referencia;
  final double? latitud;
  final double? longitud;
  final bool esPredeterminada;
  final DateTime? creadoEn;

  /// "Calle 123, referencia, ciudad" para las tarjetas de la lista.
  String get linea1 => [calle, numero].where(_esTexto).join(' ');

  String get linea2 => [referencia, ciudad].where(_esTexto).join(', ');

  String get etiqueta => alias?.trim().isNotEmpty ?? false ? alias! : 'Casa';

  static bool _esTexto(String? value) => value?.trim().isNotEmpty ?? false;

  Address copyWith({bool? esPredeterminada}) {
    return Address(
      id: id,
      calle: calle,
      ciudad: ciudad,
      alias: alias,
      numero: numero,
      referencia: referencia,
      latitud: latitud,
      longitud: longitud,
      esPredeterminada: esPredeterminada ?? this.esPredeterminada,
      creadoEn: creadoEn,
    );
  }

  @override
  List<Object?> get props => [
    id,
    calle,
    ciudad,
    alias,
    numero,
    referencia,
    latitud,
    longitud,
    esPredeterminada,
    creadoEn,
  ];
}

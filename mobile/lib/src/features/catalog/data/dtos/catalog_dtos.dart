import 'package:json_annotation/json_annotation.dart';

part 'catalog_dtos.g.dart';

@JsonSerializable()
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.orden,
    required this.activo,
    this.icon,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);

  final String id;
  final String nombre;
  final String? descripcion;
  final int orden;
  final bool activo;
  final String? icon;
}

@JsonSerializable()
class ProductDto {
  const ProductDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.disponible,
    this.categoria,
    this.stock,
    this.stockMinimo,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);

  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool disponible;
  final CategoryDto? categoria;
  final int? stock;
  final int? stockMinimo;
}

@JsonSerializable()
class ProductDetailDto {
  const ProductDetailDto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.disponible,
    this.categoria,
    this.opciones = const [],
    this.stock,
  });

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDetailDtoToJson(this);

  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool disponible;
  final CategoryDto? categoria;
  final List<ProductOptionDto> opciones;
  final int? stock;
}

@JsonSerializable()
class ProductOptionDto {
  const ProductOptionDto({
    required this.id,
    required this.nombre,
    required this.precioAdicional,
    required this.activo,
  });

  factory ProductOptionDto.fromJson(Map<String, dynamic> json) =>
      _$ProductOptionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductOptionDtoToJson(this);

  final String id;
  final String nombre;
  final double precioAdicional;
  final bool activo;
}

class PagedResponseDto<T> {
  const PagedResponseDto({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawData = (json['data'] as List<dynamic>?) ?? const [];
    return PagedResponseDto<T>(
      data: rawData
          .map((item) => itemParser(item as Map<String, dynamic>))
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

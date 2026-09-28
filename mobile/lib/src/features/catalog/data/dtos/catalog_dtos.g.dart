// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryDto _$CategoryDtoFromJson(Map<String, dynamic> json) => CategoryDto(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  orden: (json['orden'] as num).toInt(),
  activo: json['activo'] as bool,
  icon: json['icon'] as String?,
);

Map<String, dynamic> _$CategoryDtoToJson(CategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'orden': instance.orden,
      'activo': instance.activo,
      'icon': instance.icon,
    };

ProductDto _$ProductDtoFromJson(Map<String, dynamic> json) => ProductDto(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  precio: (json['precio'] as num).toDouble(),
  imagenUrl: json['imagenUrl'] as String?,
  disponible: json['disponible'] as bool,
  categoria: json['categoria'] == null
      ? null
      : CategoryDto.fromJson(json['categoria'] as Map<String, dynamic>),
  stock: (json['stock'] as num?)?.toInt(),
  stockMinimo: (json['stockMinimo'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProductDtoToJson(ProductDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'precio': instance.precio,
      'imagenUrl': instance.imagenUrl,
      'disponible': instance.disponible,
      'categoria': instance.categoria,
      'stock': instance.stock,
      'stockMinimo': instance.stockMinimo,
    };

ProductDetailDto _$ProductDetailDtoFromJson(Map<String, dynamic> json) =>
    ProductDetailDto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      imagenUrl: json['imagenUrl'] as String?,
      disponible: json['disponible'] as bool,
      categoria: json['categoria'] == null
          ? null
          : CategoryDto.fromJson(json['categoria'] as Map<String, dynamic>),
      opciones:
          (json['opciones'] as List<dynamic>?)
              ?.map((e) => ProductOptionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stock: (json['stock'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductDetailDtoToJson(ProductDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'precio': instance.precio,
      'imagenUrl': instance.imagenUrl,
      'disponible': instance.disponible,
      'categoria': instance.categoria,
      'opciones': instance.opciones,
      'stock': instance.stock,
    };

ProductOptionDto _$ProductOptionDtoFromJson(Map<String, dynamic> json) =>
    ProductOptionDto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precioAdicional: (json['precioAdicional'] as num).toDouble(),
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$ProductOptionDtoToJson(ProductOptionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'precioAdicional': instance.precioAdicional,
      'activo': instance.activo,
    };

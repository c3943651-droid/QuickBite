import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.orden,
    required this.activo,
    this.icon,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final int orden;
  final bool activo;
  final String? icon;

  @override
  List<Object?> get props => [id, nombre, descripcion, orden, activo, icon];
}

class Product extends Equatable {
  const Product({
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

  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool disponible;
  final Category? categoria;
  final int? stock;
  final int? stockMinimo;

  @override
  List<Object?> get props => [
    id,
    nombre,
    descripcion,
    precio,
    imagenUrl,
    disponible,
    categoria,
    stock,
    stockMinimo,
  ];
}

class ProductPage extends Equatable {
  const ProductPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  const ProductPage.empty()
    : items = const [],
      page = 1,
      limit = 10,
      total = 0,
      totalPages = 0;

  final List<Product> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  ProductPage merge(ProductPage next) {
    return ProductPage(
      items: [...items, ...next.items],
      page: next.page,
      limit: next.limit,
      total: next.total,
      totalPages: next.totalPages,
    );
  }

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

enum ProductSort {
  relevancia('relevancia', 'Relevancia'),
  precioAsc('precio_asc', 'Precio ascendente'),
  precioDesc('precio_desc', 'Precio descendente'),
  nombreAsc('nombre_asc', 'Nombre A-Z'),
  nombreDesc('nombre_desc', 'Nombre Z-A');

  const ProductSort(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class ProductFilter extends Equatable {
  const ProductFilter({
    this.categoryId,
    this.search,
    this.disponible = true,
    this.sort = ProductSort.relevancia,
    this.page = 1,
    this.limit = 12,
  });

  final String? categoryId;
  final String? search;
  final bool disponible;
  final ProductSort sort;
  final int page;
  final int limit;

  ProductFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? search,
    bool? disponible,
    ProductSort? sort,
    int? page,
    int? limit,
  }) {
    return ProductFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      disponible: disponible ?? this.disponible,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    categoryId,
    search,
    disponible,
    sort,
    page,
    limit,
  ];
}

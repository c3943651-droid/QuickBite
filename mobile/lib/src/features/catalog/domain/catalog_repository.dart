import 'package:equatable/equatable.dart';

import 'catalog_entities.dart';

abstract interface class CatalogRepository {
  Future<List<Category>> getCategories();

  Future<ProductPage> getProducts(ProductFilter filter);

  Future<Product> getProduct(String id);

  Future<List<ProductOption>> getProductOptions(String id);
}

class ProductOption extends Equatable {
  const ProductOption({
    required this.id,
    required this.nombre,
    required this.precioAdicional,
    required this.activo,
  });

  final String id;
  final String nombre;
  final double precioAdicional;
  final bool activo;

  @override
  List<Object?> get props => [id, nombre, precioAdicional, activo];
}

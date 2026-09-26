import '../domain/catalog_entities.dart';
import '../domain/catalog_repository.dart';
import 'catalog_remote_data_source.dart';
import 'dtos/catalog_dtos.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<List<Category>> getCategories() async {
    final dtos = await _remote.getCategories();
    return dtos.map(_toCategory).toList(growable: false);
  }

  @override
  Future<ProductPage> getProducts(ProductFilter filter) async {
    final page = await _remote.getProducts(filter);
    return ProductPage(
      items: page.data.map(_toProduct).toList(growable: false),
      page: page.page,
      limit: page.limit,
      total: page.total,
      totalPages: page.totalPages,
    );
  }

  @override
  Future<Product> getProduct(String id) async {
    final dto = await _remote.getProduct(id);
    return _toProductFromDetail(dto);
  }

  @override
  Future<List<ProductOption>> getProductOptions(String id) async {
    final dtos = await _remote.getProductOptions(id);
    return dtos
        .map(
          (dto) => ProductOption(
            id: dto.id,
            nombre: dto.nombre,
            precioAdicional: dto.precioAdicional,
            activo: dto.activo,
          ),
        )
        .toList(growable: false);
  }

  Category _toCategory(CategoryDto dto) {
    return Category(
      id: dto.id,
      nombre: dto.nombre,
      descripcion: dto.descripcion,
      orden: dto.orden,
      activo: dto.activo,
      icon: dto.icon,
    );
  }

  Product _toProduct(ProductDto dto) {
    return Product(
      id: dto.id,
      nombre: dto.nombre,
      descripcion: dto.descripcion,
      precio: dto.precio,
      imagenUrl: dto.imagenUrl,
      disponible: dto.disponible,
      categoria: dto.categoria == null ? null : _toCategory(dto.categoria!),
      stock: dto.stock,
      stockMinimo: dto.stockMinimo,
    );
  }

  Product _toProductFromDetail(ProductDetailDto dto) {
    return Product(
      id: dto.id,
      nombre: dto.nombre,
      descripcion: dto.descripcion,
      precio: dto.precio,
      imagenUrl: dto.imagenUrl,
      disponible: dto.disponible,
      categoria: dto.categoria == null ? null : _toCategory(dto.categoria!),
      stock: dto.stock,
    );
  }
}

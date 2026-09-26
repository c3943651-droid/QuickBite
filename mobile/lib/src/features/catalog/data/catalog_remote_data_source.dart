import '../../../core/network/dio_client.dart';
import '../domain/catalog_entities.dart';
import 'dtos/catalog_dtos.dart';

class CatalogRemoteDataSource {
  const CatalogRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<CategoryDto>> getCategories() async {
    final response = await _client.get('/categories');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PagedResponseDto<ProductDto>> getProducts(ProductFilter filter) async {
    final response = await _client.get(
      '/products',
      queryParameters: _queryFor(filter),
    );
    return PagedResponseDto<ProductDto>.fromJson(
      response.data as Map<String, dynamic>,
      ProductDto.fromJson,
    );
  }

  Future<ProductDetailDto> getProduct(String id) async {
    final response = await _client.get('/products/$id');
    return ProductDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProductOptionDto>> getProductOptions(String id) async {
    final response = await _client.get('/products/$id/options');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ProductOptionDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Map<String, dynamic> _queryFor(ProductFilter filter) {
    return {
      if (filter.categoryId != null) 'categoriaId': filter.categoryId,
      if (filter.search != null && filter.search!.isNotEmpty)
        'search': filter.search,
      'disponible': filter.disponible,
      'orden': filter.sort.apiValue,
      'page': filter.page,
      'limit': filter.limit,
    };
  }
}

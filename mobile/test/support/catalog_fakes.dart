import 'package:quickbite_mobile/src/features/catalog/domain/catalog_entities.dart';
import 'package:quickbite_mobile/src/features/catalog/domain/catalog_repository.dart';

const quickbiteTacos = Category(
  id: 'c1',
  nombre: 'Tacos',
  orden: 1,
  activo: true,
);
const quickbiteBebidas = Category(
  id: 'c2',
  nombre: 'Bebidas',
  orden: 2,
  activo: true,
);

const quickbitePastor = Product(
  id: 'p1',
  nombre: 'Tacos al pastor',
  precio: 85.50,
  disponible: true,
  categoria: quickbiteTacos,
);

/// Catálogo mínimo para los tests que solo necesitan que el shell del cliente
/// tenga algo que renderizar. Los tests del propio catálogo usan su doble con
/// inyección de errores (`home_screen_test.dart`).
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.error});

  Object? error;
  final List<ProductFilter> filters = [];

  @override
  Future<List<Category>> getCategories() async => const [
    quickbiteTacos,
    quickbiteBebidas,
  ];

  @override
  Future<List<PromotionBanner>> getPromotions() async => const [];

  @override
  Future<Product> getProduct(String id) => throw UnimplementedError();

  @override
  Future<List<ProductOption>> getProductOptions(String id) =>
      throw UnimplementedError();

  @override
  Future<ProductPage> getProducts(ProductFilter filter) async {
    filters.add(filter);
    if (error != null) {
      throw error!;
    }
    return const ProductPage(
      items: [quickbitePastor],
      page: 1,
      limit: 12,
      total: 1,
      totalPages: 1,
    );
  }
}

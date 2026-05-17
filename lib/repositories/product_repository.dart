import '../models/product.dart';
import '../services/api_service.dart';

/// Repository layer that sits between the presenter and the network service.
///
/// This thin wrapper gives two benefits:
///   1. Presenters are not coupled to [ApiService] directly, so the data
///      source can be swapped (e.g. a local DB) without touching presenter code.
///   2. Tests can inject a fake [ProductRepository] subclass instead of
///      mocking HTTP — see `test/presenters/products_presenter_test.dart`.
class ProductRepository {
  final ApiService _api;

  ProductRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Product>> getProducts({int limit = 30, int skip = 0}) =>
      _api.getProducts(limit: limit, skip: skip);

  Future<List<Product>> getProductsByCategory(String category,
          {int limit = 30}) =>
      _api.getProductsByCategory(category, limit: limit);

  Future<List<Product>> searchProducts(String query) =>
      _api.searchProducts(query);

  Future<List<String>> getCategories() => _api.getCategories();
}

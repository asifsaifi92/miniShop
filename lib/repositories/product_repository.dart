import '../models/product.dart';
import '../services/api_service.dart';

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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// Typed exception thrown by [ApiService] for all network failures.
/// Using a dedicated type lets callers catch only API errors without swallowing
/// unexpected exceptions from the rest of the call stack.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// HTTP client for the DummyJSON REST API.
/// All methods normalise network errors into [ApiException] so callers never
/// need to handle [SocketException], [TimeoutException], or raw HTTP errors.
class ApiService {
  static const _base = 'https://dummyjson.com';
  // 10 seconds is generous enough for slow mobile connections while still
  // surfacing hangs quickly in tests.
  static const _timeout = Duration(seconds: 10);

  /// Returns a page of products. [skip] enables infinite-scroll pagination.
  Future<List<Product>> getProducts({int limit = 30, int skip = 0}) async {
    final uri =
        Uri.parse('$_base/products?limit=$limit&skip=$skip&select=id,title,description,price,discountPercentage,rating,stock,brand,category,thumbnail,images');
    return _fetchProducts(uri);
  }

  /// Returns all products in [category] up to [limit] items.
  Future<List<Product>> getProductsByCategory(String category,
      {int limit = 30}) async {
    final uri = Uri.parse(
        '$_base/products/category/$category?limit=$limit');
    return _fetchProducts(uri);
  }

  /// Full-text product search delegated to the DummyJSON search endpoint.
  Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.parse('$_base/products/search?q=${Uri.encodeComponent(query)}');
    return _fetchProducts(uri);
  }

  /// Returns category slugs (e.g. "smartphones", "laptops").
  /// The API returns objects like `{"slug":"...", "name":"..."}` so we extract
  /// only the slug field and filter out any blank entries.
  Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/products/categories'))
          .timeout(_timeout);
      _checkStatus(response);
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => e['slug']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on HttpException {
      throw ApiException('Network error');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Something went wrong');
    }
  }

  /// Shared fetch+decode logic used by all product-list endpoints.
  Future<List<Product>> _fetchProducts(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(_timeout);
      _checkStatus(response);
      final data = jsonDecode(response.body);
      final List<dynamic> products = data['products'] ?? [];
      return products.map((e) => Product.fromJson(e)).toList();
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on HttpException {
      throw ApiException('Network error');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Something went wrong');
    }
  }

  /// Throws [ApiException] for any non-2xx response.
  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Server error (${response.statusCode})');
    }
  }
}

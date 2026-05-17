import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _base = 'https://dummyjson.com';
  static const _timeout = Duration(seconds: 10);

  Future<List<Product>> getProducts({int limit = 30, int skip = 0}) async {
    final uri =
        Uri.parse('$_base/products?limit=$limit&skip=$skip&select=id,title,description,price,discountPercentage,rating,stock,brand,category,thumbnail,images');
    return _fetchProducts(uri);
  }

  Future<List<Product>> getProductsByCategory(String category,
      {int limit = 30}) async {
    final uri = Uri.parse(
        '$_base/products/category/$category?limit=$limit');
    return _fetchProducts(uri);
  }

  Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.parse('$_base/products/search?q=${Uri.encodeComponent(query)}');
    return _fetchProducts(uri);
  }

  Future<Product> getProduct(int id) async {
    try {
      final response =
          await http.get(Uri.parse('$_base/products/$id')).timeout(_timeout);
      _checkStatus(response);
      return Product.fromJson(jsonDecode(response.body));
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

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Server error (${response.statusCode})');
    }
  }
}

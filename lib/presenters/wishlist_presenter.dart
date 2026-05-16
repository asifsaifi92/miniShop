import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/wishlist_contract.dart';
import '../models/product.dart';

class WishlistPresenter extends ChangeNotifier implements IWishlistPresenter {
  final Map<int, Product> _items = {};
  static const _prefKey = 'wishlist';

  WishlistPresenter() {
    Future.microtask(_load);
  }

  @override
  List<Product> get items => _items.values.toList();

  @override
  bool contains(int productId) => _items.containsKey(productId);

  @override
  void toggle(Product product) {
    if (_items.containsKey(product.id)) {
      _items.remove(product.id);
    } else {
      _items[product.id] = product;
    }
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.values
        .map((p) => {
              'id': p.id,
              'title': p.title,
              'description': p.description,
              'price': p.price,
              'discountPercentage': p.discountPercentage,
              'rating': p.rating,
              'stock': p.stock,
              'brand': p.brand,
              'category': p.category,
              'thumbnail': p.thumbnail,
              'images': p.images,
            })
        .toList();
    await prefs.setString(_prefKey, jsonEncode(data));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final List<dynamic> data = jsonDecode(raw);
      for (final item in data) {
        final product = Product(
          id: (item['id'] as num?)?.toInt() ?? 0,
          title: item['title'] as String? ?? '',
          description: item['description'] as String? ?? '',
          price: (item['price'] as num?)?.toDouble() ?? 0,
          discountPercentage:
              (item['discountPercentage'] as num?)?.toDouble() ?? 0,
          rating: (item['rating'] as num?)?.toDouble() ?? 0,
          stock: (item['stock'] as num?)?.toInt() ?? 0,
          brand: item['brand'] as String? ?? '',
          category: item['category'] as String? ?? '',
          thumbnail: item['thumbnail'] as String? ?? '',
          images: List<String>.from(item['images'] as List? ?? []),
        );
        _items[product.id] = product;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[WishlistPresenter] Failed to load persisted wishlist: $e');
    }
  }
}

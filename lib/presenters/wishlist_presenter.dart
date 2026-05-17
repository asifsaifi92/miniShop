import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/wishlist_contract.dart';
import '../models/product.dart';

/// Manages the wishlist and persists it to SharedPreferences.
///
/// Uses a [Map<int, Product>] internally (keyed by product ID) so [contains]
/// and [toggle] are O(1) — important because the heart icon on every
/// product card calls [contains] on each rebuild.
class WishlistPresenter extends ChangeNotifier implements IWishlistPresenter {
  final Map<int, Product> _items = {};
  static const _prefKey = 'wishlist';

  WishlistPresenter() {
    // Defer disk read to avoid "setState during build" in ChangeNotifier init.
    Future.microtask(_load);
  }

  @override
  List<Product> get items => _items.values.toList();

  @override
  bool contains(int productId) => _items.containsKey(productId);

  /// Adds the product if not saved, removes it if already saved.
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_items.values.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint('[WishlistPresenter] Failed to persist wishlist: $e');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final List<dynamic> data = jsonDecode(raw);
      for (final item in data) {
        final product =
            Product.fromJson(Map<String, dynamic>.from(item as Map));
        _items[product.id] = product;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[WishlistPresenter] Failed to load persisted wishlist: $e');
    }
  }
}

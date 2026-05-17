import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/cart_contract.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartPresenter extends ChangeNotifier implements ICartPresenter {
  final Map<int, CartItem> _items = {};
  static const _prefKey = 'cart_items';

  CartPresenter() {
    Future.microtask(_loadFromPrefs);
  }

  @override
  List<CartItem> get items => _items.values.toList();

  @override
  int get itemCount => _items.values.fold(0, (sum, e) => sum + e.quantity);

  @override
  double get total => _items.values.fold(0.0, (sum, e) => sum + e.total);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool contains(int productId) => _items.containsKey(productId);

  @override
  int quantityOf(int productId) => _items[productId]?.quantity ?? 0;

  @override
  void addProduct(Product product) {
    final existing = _items[product.id];
    _items[product.id] = existing != null
        ? existing.copyWith(quantity: existing.quantity + 1)
        : CartItem(product: product);
    _persist();
    notifyListeners();
  }

  @override
  void removeProduct(int productId) {
    _items.remove(productId);
    _persist();
    notifyListeners();
  }

  @override
  void increment(int productId) {
    final item = _items[productId];
    if (item == null) return;
    _items[productId] = item.copyWith(quantity: item.quantity + 1);
    _persist();
    notifyListeners();
  }

  @override
  void decrement(int productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      removeProduct(productId);
    } else {
      _items[productId] = item.copyWith(quantity: item.quantity - 1);
      _persist();
      notifyListeners();
    }
  }

  @override
  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_items.values.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[CartPresenter] Failed to persist cart: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final List<dynamic> data = jsonDecode(raw);
      for (final item in data) {
        final cartItem =
            CartItem.fromJson(Map<String, dynamic>.from(item as Map));
        _items[cartItem.product.id] = cartItem;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CartPresenter] Failed to load persisted cart: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/cart_contract.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Manages the shopping cart and persists it to SharedPreferences.
///
/// Internal storage is a [Map<int, CartItem>] keyed by product ID so all
/// lookups (contains, quantityOf, increment, decrement) are O(1).
///
/// [Future.microtask] in the constructor defers the async SharedPreferences
/// load until after the first build cycle, avoiding "setState during build".
class CartPresenter extends ChangeNotifier implements ICartPresenter {
  final Map<int, CartItem> _items = {};
  static const _prefKey = 'cart_items';

  CartPresenter() {
    // Defer the async disk read to the next microtask so the constructor
    // completes synchronously and MultiProvider can finish its setup.
    Future.microtask(_loadFromPrefs);
  }

  @override
  List<CartItem> get items => _items.values.toList();

  /// Total number of units across all products (e.g. 2×A + 3×B = 5).
  @override
  int get itemCount => _items.values.fold(0, (sum, e) => sum + e.quantity);

  /// Grand total: sum of (discounted price × quantity) for every line.
  @override
  double get total => _items.values.fold(0.0, (sum, e) => sum + e.total);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool contains(int productId) => _items.containsKey(productId);

  @override
  int quantityOf(int productId) => _items[productId]?.quantity ?? 0;

  /// If the product is already in the cart its quantity is incremented;
  /// otherwise a new [CartItem] with quantity=1 is inserted.
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

  /// Removes the item entirely when quantity would drop below 1.
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

  /// Writes the cart as a JSON array to SharedPreferences.
  /// Failures are logged but do not propagate — a write error is non-fatal
  /// because the in-memory state is still correct for the current session.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_items.values.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[CartPresenter] Failed to persist cart: $e');
    }
  }

  /// Rehydrates the cart from disk on app start.
  /// Each stored map is explicitly cast to `Map<String, dynamic>` because
  /// `jsonDecode` returns `Map<String, Object?>` which CartItem.fromJson
  /// requires to be explicitly typed.
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

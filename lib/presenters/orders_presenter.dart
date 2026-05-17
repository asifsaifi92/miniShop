import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/orders_contract.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Stores the order history in memory and persists it to SharedPreferences.
///
/// Orders are appended chronologically in [_orders] but exposed in reverse
/// (newest first) through the [orders] getter so the UI always shows the
/// most recent order at the top without sorting on every build.
class OrdersPresenter extends ChangeNotifier implements IOrdersPresenter {
  final List<Order> _orders = [];
  static const _prefKey = 'orders';

  OrdersPresenter() {
    // Defer disk read — same pattern as CartPresenter and WishlistPresenter.
    Future.microtask(_load);
  }

  /// Returns orders newest-first. The unmodifiable wrapper prevents accidental
  /// mutation from outside this class.
  @override
  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

  /// Creates a new [Order] from the current cart snapshot, persists it, and
  /// returns it so [CheckoutScreen] can navigate to the success screen.
  ///
  /// The order ID uses millisecondsSinceEpoch to guarantee uniqueness
  /// within a single device session.
  @override
  Order placeOrder({
    required List<CartItem> items,
    required double total,
    required String name,
    required String address,
    required String phone,
  }) {
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: List.from(items),
      total: total,
      name: name,
      address: address,
      phone: phone,
      placedAt: DateTime.now(),
    );
    _orders.add(order);
    _persist();
    notifyListeners();
    return order;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_orders.map((o) => o.toJson()).toList()));
    } catch (e) {
      debugPrint('[OrdersPresenter] Failed to persist orders: $e');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return;
      final List<dynamic> data = jsonDecode(raw);
      for (final o in data) {
        _orders.add(Order.fromJson(Map<String, dynamic>.from(o as Map)));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[OrdersPresenter] Failed to load persisted orders: $e');
    }
  }
}

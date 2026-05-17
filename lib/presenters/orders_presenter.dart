import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/orders_contract.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrdersPresenter extends ChangeNotifier implements IOrdersPresenter {
  final List<Order> _orders = [];
  static const _prefKey = 'orders';

  OrdersPresenter() {
    Future.microtask(_load);
  }

  @override
  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

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

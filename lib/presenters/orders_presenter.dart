import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../contracts/orders_contract.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final data = _orders
        .map((o) => {
              'id': o.id,
              'total': o.total,
              'name': o.name,
              'address': o.address,
              'phone': o.phone,
              'placedAt': o.placedAt.toIso8601String(),
              'items': o.items
                  .map((i) => {
                        'quantity': i.quantity,
                        'id': i.product.id,
                        'title': i.product.title,
                        'description': i.product.description,
                        'price': i.product.price,
                        'discountPercentage': i.product.discountPercentage,
                        'rating': i.product.rating,
                        'stock': i.product.stock,
                        'brand': i.product.brand,
                        'category': i.product.category,
                        'thumbnail': i.product.thumbnail,
                        'images': i.product.images,
                      })
                  .toList(),
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
      for (final o in data) {
        final items = (o['items'] as List<dynamic>? ?? []).map((i) {
          final product = Product(
            id: (i['id'] as num?)?.toInt() ?? 0,
            title: i['title'] as String? ?? '',
            description: i['description'] as String? ?? '',
            price: (i['price'] as num?)?.toDouble() ?? 0,
            discountPercentage:
                (i['discountPercentage'] as num?)?.toDouble() ?? 0,
            rating: (i['rating'] as num?)?.toDouble() ?? 0,
            stock: (i['stock'] as num?)?.toInt() ?? 0,
            brand: i['brand'] as String? ?? '',
            category: i['category'] as String? ?? '',
            thumbnail: i['thumbnail'] as String? ?? '',
            images: List<String>.from(i['images'] as List? ?? []),
          );
          return CartItem(
              product: product,
              quantity: (i['quantity'] as num?)?.toInt() ?? 1);
        }).toList();

        _orders.add(Order(
          id: o['id'] as String? ?? '',
          items: items,
          total: (o['total'] as num?)?.toDouble() ?? 0,
          name: o['name'] as String? ?? '',
          address: o['address'] as String? ?? '',
          phone: o['phone'] as String? ?? '',
          placedAt: DateTime.tryParse(o['placedAt'] as String? ?? '') ??
              DateTime.now(),
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[OrdersPresenter] Failed to load persisted orders: $e');
    }
  }
}

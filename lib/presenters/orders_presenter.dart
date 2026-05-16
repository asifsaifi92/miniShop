import 'package:flutter/foundation.dart';
import '../contracts/orders_contract.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrdersPresenter extends ChangeNotifier implements IOrdersPresenter {
  final List<Order> _orders = [];

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
    notifyListeners();
    return order;
  }
}

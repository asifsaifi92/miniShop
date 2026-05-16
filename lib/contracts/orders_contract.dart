import '../models/cart_item.dart';
import '../models/order.dart';

abstract class IOrdersPresenter {
  List<Order> get orders;

  Order placeOrder({
    required List<CartItem> items,
    required double total,
    required String name,
    required String address,
    required String phone,
  });
}

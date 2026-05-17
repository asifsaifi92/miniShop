import '../models/cart_item.dart';
import '../models/order.dart';

/// Contract for the orders presenter.
abstract class IOrdersPresenter {
  /// All placed orders, most recent first.
  List<Order> get orders;

  /// Creates an order from the current cart snapshot, persists it, and returns
  /// the newly created [Order] so the caller can navigate to the success screen.
  Order placeOrder({
    required List<CartItem> items,
    required double total,
    required String name,
    required String address,
    required String phone,
  });
}

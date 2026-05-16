import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final String name;
  final String address;
  final String phone;
  final DateTime placedAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.name,
    required this.address,
    required this.phone,
    required this.placedAt,
  });
}

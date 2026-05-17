import 'cart_item.dart';

/// Snapshot of a completed purchase. Once created an order is never mutated —
/// the list of items and totals are captured at the moment of checkout.
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

  /// [placedAt] is stored as ISO-8601 so it survives JSON serialisation
  /// without depending on a platform-specific date format.
  Map<String, dynamic> toJson() => {
        'id': id,
        'total': total,
        'name': name,
        'address': address,
        'phone': phone,
        'placedAt': placedAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        // Fall back to now if the stored string is corrupt rather than crash.
        placedAt:
            DateTime.tryParse(json['placedAt'] as String? ?? '') ?? DateTime.now(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList(),
      );
}

import 'product.dart';

/// Pairs a [Product] with a quantity. Immutable — mutations return a new
/// instance via [copyWith] so the presenter can detect changes reliably.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  /// Line total using the discounted price, not the original price.
  double get total => product.discountedPrice * quantity;

  /// Returns a new CartItem with only [quantity] changed; product is preserved.
  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );

  /// Flattens product fields and quantity into one map so a single JSON entry
  /// in SharedPreferences represents the complete cart item.
  Map<String, dynamic> toJson() => {
        ...product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

import '../models/cart_item.dart';
import '../models/product.dart';

/// Contract for the cart presenter. Views use this interface so the concrete
/// presenter can be swapped or mocked without touching any screen code.
abstract class ICartPresenter {
  /// Ordered list of all cart items.
  List<CartItem> get items;

  /// Sum of quantities across all items (shown on the cart badge).
  int get itemCount;

  /// Sum of all line totals (discounted price × quantity).
  double get total;

  bool get isEmpty;

  bool contains(int productId);
  int quantityOf(int productId);

  /// Adds the product or increments its quantity if already in the cart.
  void addProduct(Product product);

  void removeProduct(int productId);
  void increment(int productId);

  /// Decrements quantity; removes the item entirely when quantity reaches 1.
  void decrement(int productId);

  void clear();
}

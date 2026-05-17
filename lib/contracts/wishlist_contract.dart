import '../models/product.dart';

/// Contract for the wishlist presenter.
abstract class IWishlistPresenter {
  /// All saved products.
  List<Product> get items;

  bool contains(int productId);

  /// Adds the product if absent, removes it if already saved (toggle pattern).
  void toggle(Product product);
}

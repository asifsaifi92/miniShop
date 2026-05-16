import '../models/product.dart';

abstract class IWishlistPresenter {
  List<Product> get items;

  bool contains(int productId);
  void toggle(Product product);
}

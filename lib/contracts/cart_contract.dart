import '../models/cart_item.dart';
import '../models/product.dart';

abstract class ICartPresenter {
  List<CartItem> get items;
  int get itemCount;
  double get total;
  bool get isEmpty;

  bool contains(int productId);
  int quantityOf(int productId);
  void addProduct(Product product);
  void removeProduct(int productId);
  void increment(int productId);
  void decrement(int productId);
  void clear();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/models/cart_item.dart';
import 'package:minishop/models/product.dart';

void main() {
  final product = Product(
    id: 1,
    title: 'Widget',
    description: '',
    price: 50.0,
    discountPercentage: 20.0,
    rating: 4.0,
    stock: 5,
    brand: '',
    category: '',
    thumbnail: '',
    images: [],
  );

  group('CartItem.total', () {
    test('uses discounted price × quantity', () {
      final item = CartItem(product: product, quantity: 3);
      // discountedPrice = 50 * 0.8 = 40
      expect(item.total, closeTo(120.0, 0.001));
    });

    test('defaults quantity to 1', () {
      final item = CartItem(product: product);
      expect(item.quantity, 1);
      expect(item.total, closeTo(40.0, 0.001));
    });
  });

  group('CartItem.copyWith', () {
    test('creates new item with updated quantity', () {
      final item = CartItem(product: product, quantity: 2);
      final updated = item.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.product, same(product));
    });

    test('preserves quantity when not specified', () {
      final item = CartItem(product: product, quantity: 3);
      final copy = item.copyWith();
      expect(copy.quantity, 3);
    });

    test('original is not mutated', () {
      final item = CartItem(product: product, quantity: 2);
      item.copyWith(quantity: 99);
      expect(item.quantity, 2);
    });
  });
}

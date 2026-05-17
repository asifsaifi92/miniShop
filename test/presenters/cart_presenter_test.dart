import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/presenters/cart_presenter.dart';
import 'package:minishop/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CartPresenter cart;

  Product makeProduct(int id, {double price = 100.0, double discount = 0.0}) {
    return Product(
      id: id,
      title: 'Product $id',
      description: '',
      price: price,
      discountPercentage: discount,
      rating: 4.0,
      stock: 10,
      brand: '',
      category: '',
      thumbnail: '',
      images: [],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cart = CartPresenter();
    await Future.delayed(Duration.zero); // drain microtask queue
  });

  group('addProduct', () {
    test('adds a new product with quantity 1', () {
      cart.addProduct(makeProduct(1));
      expect(cart.contains(1), isTrue);
      expect(cart.quantityOf(1), 1);
      expect(cart.itemCount, 1);
    });

    test('increments quantity when same product added again', () {
      final p = makeProduct(1);
      cart.addProduct(p);
      cart.addProduct(p);
      expect(cart.quantityOf(1), 2);
      expect(cart.itemCount, 2);
    });

    test('adding two different products tracks both', () {
      cart.addProduct(makeProduct(1));
      cart.addProduct(makeProduct(2));
      expect(cart.itemCount, 2);
      expect(cart.items.length, 2);
    });
  });

  group('removeProduct', () {
    test('removes product completely regardless of quantity', () {
      cart.addProduct(makeProduct(1));
      cart.addProduct(makeProduct(1));
      cart.removeProduct(1);
      expect(cart.contains(1), isFalse);
      expect(cart.itemCount, 0);
    });

    test('no-op for non-existent id', () {
      cart.removeProduct(999);
      expect(cart.isEmpty, isTrue);
    });
  });

  group('increment / decrement', () {
    test('increment increases quantity by 1', () {
      cart.addProduct(makeProduct(1));
      cart.increment(1);
      expect(cart.quantityOf(1), 2);
    });

    test('decrement decreases quantity by 1', () {
      cart.addProduct(makeProduct(1));
      cart.increment(1);
      cart.decrement(1);
      expect(cart.quantityOf(1), 1);
    });

    test('decrement at quantity 1 removes item', () {
      cart.addProduct(makeProduct(1));
      cart.decrement(1);
      expect(cart.contains(1), isFalse);
    });

    test('increment / decrement on unknown id are no-ops', () {
      cart.increment(42);
      cart.decrement(42);
      expect(cart.isEmpty, isTrue);
    });
  });

  group('total', () {
    test('sums discounted prices × quantities', () {
      // price 100, 20% off → 80 each
      cart.addProduct(makeProduct(1, price: 100.0, discount: 20.0));
      cart.addProduct(makeProduct(1, price: 100.0, discount: 20.0));
      cart.addProduct(makeProduct(2, price: 50.0, discount: 0.0));
      // 2 × 80 + 1 × 50 = 210
      expect(cart.total, closeTo(210.0, 0.001));
    });

    test('total is 0 for empty cart', () {
      expect(cart.total, 0.0);
    });
  });

  group('clear', () {
    test('removes all items', () {
      cart.addProduct(makeProduct(1));
      cart.addProduct(makeProduct(2));
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
    });
  });

  group('notifyListeners', () {
    test('notifies on add', () {
      var notified = false;
      cart.addListener(() => notified = true);
      cart.addProduct(makeProduct(1));
      expect(notified, isTrue);
    });

    test('notifies on remove', () {
      cart.addProduct(makeProduct(1));
      var notified = false;
      cart.addListener(() => notified = true);
      cart.removeProduct(1);
      expect(notified, isTrue);
    });

    test('notifies on clear', () {
      cart.addProduct(makeProduct(1));
      var notified = false;
      cart.addListener(() => notified = true);
      cart.clear();
      expect(notified, isTrue);
    });
  });
}

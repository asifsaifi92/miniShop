import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/presenters/wishlist_presenter.dart';
import 'package:minishop/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late WishlistPresenter wishlist;

  Product makeProduct(int id) => Product(
        id: id,
        title: 'Product $id',
        description: '',
        price: 10.0,
        discountPercentage: 0.0,
        rating: 4.0,
        stock: 5,
        brand: '',
        category: '',
        thumbnail: '',
        images: [],
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    wishlist = WishlistPresenter();
    await Future.delayed(Duration.zero);
  });

  group('toggle', () {
    test('adds product when not present', () {
      wishlist.toggle(makeProduct(1));
      expect(wishlist.contains(1), isTrue);
      expect(wishlist.items.length, 1);
    });

    test('removes product when already present', () {
      wishlist.toggle(makeProduct(1));
      wishlist.toggle(makeProduct(1));
      expect(wishlist.contains(1), isFalse);
      expect(wishlist.items, isEmpty);
    });

    test('toggling multiple products tracks all independently', () {
      wishlist.toggle(makeProduct(1));
      wishlist.toggle(makeProduct(2));
      expect(wishlist.items.length, 2);
      wishlist.toggle(makeProduct(1));
      expect(wishlist.items.length, 1);
      expect(wishlist.contains(2), isTrue);
    });
  });

  group('contains', () {
    test('returns false for product not in wishlist', () {
      expect(wishlist.contains(99), isFalse);
    });
  });

  group('notifyListeners', () {
    test('notifies on toggle add', () {
      var notified = false;
      wishlist.addListener(() => notified = true);
      wishlist.toggle(makeProduct(1));
      expect(notified, isTrue);
    });

    test('notifies on toggle remove', () {
      wishlist.toggle(makeProduct(1));
      var notified = false;
      wishlist.addListener(() => notified = true);
      wishlist.toggle(makeProduct(1));
      expect(notified, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/presenters/orders_presenter.dart';
import 'package:minishop/models/cart_item.dart';
import 'package:minishop/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OrdersPresenter presenter;

  final product = Product(
    id: 1,
    title: 'Widget',
    description: '',
    price: 50.0,
    discountPercentage: 0.0,
    rating: 4.0,
    stock: 10,
    brand: '',
    category: '',
    thumbnail: '',
    images: [],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    presenter = OrdersPresenter();
    await Future.delayed(Duration.zero);
  });

  group('placeOrder', () {
    test('returns order with correct fields', () {
      final items = [CartItem(product: product, quantity: 2)];
      final order = presenter.placeOrder(
        items: items,
        total: 100.0,
        name: 'John Doe',
        address: '123 Main St',
        phone: '1234567890',
      );

      expect(order.id, startsWith('ORD-'));
      expect(order.total, 100.0);
      expect(order.name, 'John Doe');
      expect(order.address, '123 Main St');
      expect(order.phone, '1234567890');
      expect(order.items.length, 1);
    });

    test('order is added to the list', () {
      presenter.placeOrder(
        items: [CartItem(product: product)],
        total: 50.0,
        name: 'Alice',
        address: 'Addr',
        phone: '123',
      );
      expect(presenter.orders.length, 1);
    });

    test('multiple orders are listed newest first', () {
      presenter.placeOrder(
          items: [], total: 10.0, name: 'A', address: 'A', phone: '1');
      presenter.placeOrder(
          items: [], total: 20.0, name: 'B', address: 'B', phone: '2');

      expect(presenter.orders.first.name, 'B');
      expect(presenter.orders.last.name, 'A');
    });

    test('order id is unique per call', () async {
      final o1 = presenter.placeOrder(
          items: [], total: 1.0, name: 'X', address: 'X', phone: '1');
      await Future.delayed(const Duration(milliseconds: 2));
      final o2 = presenter.placeOrder(
          items: [], total: 2.0, name: 'Y', address: 'Y', phone: '2');
      expect(o1.id, isNot(equals(o2.id)));
    });

    test('notifies listeners after placing order', () {
      var notified = false;
      presenter.addListener(() => notified = true);
      presenter.placeOrder(
          items: [], total: 0, name: 'Z', address: 'Z', phone: '0');
      expect(notified, isTrue);
    });
  });

  group('persistence', () {
    test('orders survive a presenter restart', () async {
      presenter.placeOrder(
        items: [CartItem(product: product, quantity: 1)],
        total: 50.0,
        name: 'Persist Me',
        address: '1 Save St',
        phone: '9876543210',
      );
      await Future.delayed(Duration.zero); // allow _persist to complete

      final reloaded = OrdersPresenter();
      await Future.delayed(Duration.zero);

      expect(reloaded.orders.length, 1);
      expect(reloaded.orders.first.name, 'Persist Me');
      expect(reloaded.orders.first.total, 50.0);
    });
  });
}

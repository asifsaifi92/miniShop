import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 1,
        'title': 'Test Product',
        'description': 'A desc',
        'price': 100.0,
        'discountPercentage': 10.0,
        'rating': 4.5,
        'stock': 20,
        'brand': 'BrandX',
        'category': 'electronics',
        'thumbnail': 'https://example.com/img.png',
        'images': ['https://example.com/1.png', 'https://example.com/2.png'],
      };

      final p = Product.fromJson(json);

      expect(p.id, 1);
      expect(p.title, 'Test Product');
      expect(p.price, 100.0);
      expect(p.discountPercentage, 10.0);
      expect(p.rating, 4.5);
      expect(p.stock, 20);
      expect(p.images.length, 2);
    });

    test('uses defaults for missing/null fields', () {
      final p = Product.fromJson({'id': 5});

      expect(p.id, 5);
      expect(p.title, '');
      expect(p.price, 0.0);
      expect(p.discountPercentage, 0.0);
      expect(p.images, isEmpty);
    });

    test('id falls back to 0 when null', () {
      final p = Product.fromJson({'id': null});
      expect(p.id, 0);
    });

    test('handles num id (e.g. 1.0 from JSON)', () {
      final p = Product.fromJson({'id': 7.0});
      expect(p.id, 7);
    });
  });

  group('Product.discountedPrice', () {
    test('applies discount correctly', () {
      final p = _product(price: 200.0, discount: 25.0);
      expect(p.discountedPrice, closeTo(150.0, 0.001));
    });

    test('returns full price when no discount', () {
      final p = _product(price: 99.99, discount: 0.0);
      expect(p.discountedPrice, 99.99);
    });
  });

  group('Product.hasDiscount', () {
    test('true when discountPercentage > 0', () {
      expect(_product(discount: 5.0).hasDiscount, isTrue);
    });

    test('false when discountPercentage is 0', () {
      expect(_product(discount: 0.0).hasDiscount, isFalse);
    });
  });
}

Product _product({double price = 100.0, double discount = 0.0}) {
  return Product(
    id: 1,
    title: 'Test',
    description: '',
    price: price,
    discountPercentage: discount,
    rating: 4.0,
    stock: 10,
    brand: 'Brand',
    category: 'cat',
    thumbnail: '',
    images: [],
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/contracts/products_contract.dart';
import 'package:minishop/models/product.dart';
import 'package:minishop/presenters/products_presenter.dart';
import 'package:minishop/repositories/product_repository.dart';
import 'package:minishop/services/api_service.dart';

// ── Fake repository that returns controlled data without hitting the network ──
class _FakeRepository extends ProductRepository {
  final List<Product> _products;
  final Exception? _error;

  _FakeRepository({List<Product> products = const [], Exception? error})
      : _products = products,
        _error = error,
        super();

  @override
  Future<List<Product>> getProducts({int limit = 30, int skip = 0}) async {
    if (_error != null) throw _error;
    return _products;
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    if (_error != null) throw _error;
    return _products
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category,
      {int limit = 30}) async {
    if (_error != null) throw _error;
    return _products.where((p) => p.category == category).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    if (_error != null) throw _error;
    return _products.map((p) => p.category).toSet().toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Product makeProduct(int id,
    {double price = 100.0, double discount = 0.0, double rating = 4.0, String category = 'electronics'}) {
  return Product(
    id: id,
    title: 'Product $id',
    description: '',
    price: price,
    discountPercentage: discount,
    rating: rating,
    stock: 10,
    brand: '',
    category: category,
    thumbnail: '',
    images: [],
  );
}

void main() {
  group('ProductsPresenter initial state', () {
    test('starts idle with empty lists', () {
      final presenter = ProductsPresenter(
          repository: _FakeRepository());
      expect(presenter.state, LoadState.idle);
      expect(presenter.products, isEmpty);
      expect(presenter.deals, isEmpty);
    });
  });

  group('init / loadProducts', () {
    test('moves to loaded state after init', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [makeProduct(1)]));
      await presenter.init();
      expect(presenter.state, LoadState.loaded);
      expect(presenter.products.length, 1);
    });

    test('sets error state when repository throws', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(
              error: ApiException('No internet connection')));
      await presenter.init();
      expect(presenter.state, LoadState.error);
      expect(presenter.errorMessage, 'No internet connection');
      expect(presenter.products, isEmpty);
    });

    test('init is idempotent — second call is a no-op once loaded', () async {
      var callCount = 0;
      final repo = _CountingRepository(onCall: () => callCount++);
      final presenter = ProductsPresenter(repository: repo);
      await presenter.init();
      await presenter.init(); // should not trigger another load
      expect(callCount, 1);
    });
  });

  group('deals', () {
    test('returns products with discount >= 15%', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [
        makeProduct(1, discount: 20.0),
        makeProduct(2, discount: 10.0),
        makeProduct(3, discount: 15.0),
        makeProduct(4, discount: 0.0),
      ]));
      await presenter.init();
      final deals = presenter.deals;
      expect(deals.map((p) => p.id), containsAll([1, 3]));
      expect(deals.any((p) => p.id == 2), isFalse);
      expect(deals.any((p) => p.id == 4), isFalse);
    });

    test('deals are sorted by discount descending', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [
        makeProduct(1, discount: 15.0),
        makeProduct(2, discount: 30.0),
        makeProduct(3, discount: 20.0),
      ]));
      await presenter.init();
      final discounts = presenter.deals.map((p) => p.discountPercentage).toList();
      expect(discounts, equals([30.0, 20.0, 15.0]));
    });
  });

  group('setSort', () {
    late ProductsPresenter presenter;

    setUp(() async {
      presenter = ProductsPresenter(
          repository: _FakeRepository(products: [
        makeProduct(1, price: 300.0, rating: 3.5),
        makeProduct(2, price: 100.0, rating: 4.8),
        makeProduct(3, price: 200.0, rating: 4.2),
      ]));
      await presenter.init();
    });

    test('priceLow sorts cheapest first', () {
      presenter.setSort(SortOption.priceLow);
      final prices =
          presenter.products.map((p) => p.discountedPrice).toList();
      expect(prices, equals([100.0, 200.0, 300.0]));
    });

    test('priceHigh sorts most expensive first', () {
      presenter.setSort(SortOption.priceHigh);
      final prices =
          presenter.products.map((p) => p.discountedPrice).toList();
      expect(prices, equals([300.0, 200.0, 100.0]));
    });

    test('ratingHigh sorts highest rated first', () {
      presenter.setSort(SortOption.ratingHigh);
      final ratings = presenter.products.map((p) => p.rating).toList();
      expect(ratings, equals([4.8, 4.2, 3.5]));
    });

    test('setSort none restores original order', () async {
      presenter.setSort(SortOption.priceLow);
      presenter.setSort(SortOption.none);
      // After none, order matches what repo returned
      final ids = presenter.products.map((p) => p.id).toList();
      expect(ids, equals([1, 2, 3]));
    });

    test('setSort with same option is a no-op (no notification)', () {
      presenter.setSort(SortOption.priceLow);
      var notified = false;
      presenter.addListener(() => notified = true);
      presenter.setSort(SortOption.priceLow);
      expect(notified, isFalse);
    });
  });

  group('selectCategory', () {
    test('filters by category', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [
        makeProduct(1, category: 'electronics'),
        makeProduct(2, category: 'clothing'),
      ]));
      await presenter.init();
      await presenter.selectCategory('electronics');
      expect(presenter.products.every((p) => p.category == 'electronics'),
          isTrue);
    });

    test('clears search query when category selected', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [makeProduct(1)]));
      await presenter.init();
      await presenter.search('phone');
      await presenter.selectCategory('electronics');
      expect(presenter.searchQuery, '');
    });

    test('same category twice does not reload', () async {
      var callCount = 0;
      final repo = _CountingRepository(onCall: () => callCount++);
      final presenter = ProductsPresenter(repository: repo);
      await presenter.init();
      final before = callCount;
      await presenter.selectCategory('all');
      expect(callCount, before); // no extra call
    });
  });

  group('search', () {
    test('clears selected category when searching', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [makeProduct(1)]));
      await presenter.init();
      await presenter.selectCategory('electronics');
      await presenter.search('widget');
      expect(presenter.selectedCategory, 'all');
    });
  });

  group('clearSearch', () {
    test('is a no-op when already empty', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [makeProduct(1)]));
      await presenter.init();
      var notified = false;
      presenter.addListener(() => notified = true);
      presenter.clearSearch();
      expect(notified, isFalse);
    });
  });

  group('categories getter', () {
    test('always includes "all" as first entry', () async {
      final presenter = ProductsPresenter(
          repository: _FakeRepository(products: [
        makeProduct(1, category: 'toys'),
        makeProduct(2, category: 'books'),
      ]));
      await presenter.init();
      expect(presenter.categories.first, 'all');
    });
  });
}

// Counts how many times getProducts is called
class _CountingRepository extends ProductRepository {
  final void Function() onCall;
  _CountingRepository({required this.onCall}) : super();

  @override
  Future<List<Product>> getProducts({int limit = 30, int skip = 0}) async {
    onCall();
    return [];
  }

  @override
  Future<List<String>> getCategories() async => [];

  @override
  Future<List<Product>> searchProducts(String query) async => [];

  @override
  Future<List<Product>> getProductsByCategory(String category,
      {int limit = 30}) async => [];
}

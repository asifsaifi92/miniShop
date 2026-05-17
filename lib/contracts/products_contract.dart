import '../models/product.dart';

/// Tracks the async lifecycle of a data-fetch operation.
enum LoadState { idle, loading, loaded, error }

/// Available sort modes for the product grid.
enum SortOption { none, priceLow, priceHigh, ratingHigh }

/// Human-readable label for each sort option, used by the sort bottom sheet.
extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.none:
        return 'Default';
      case SortOption.priceLow:
        return 'Price: Low to High';
      case SortOption.priceHigh:
        return 'Price: High to Low';
      case SortOption.ratingHigh:
        return 'Top Rated';
    }
  }
}

/// Contract that the ProductsPresenter must satisfy.
/// Views depend on this interface, not on the concrete presenter, which keeps
/// the View layer decoupled and makes the presenter easy to mock in tests.
abstract class IProductsPresenter {
  /// Currently visible (and possibly sorted) product list.
  List<Product> get products;

  /// Products with ≥15% discount, pre-sorted by discount percentage descending.
  List<Product> get deals;

  /// ['all', ...category slugs fetched from the API].
  List<String> get categories;

  String get selectedCategory;
  String get searchQuery;
  SortOption get sortOption;
  LoadState get state;
  String get errorMessage;

  /// False when all pages have been fetched or a filter/search is active.
  bool get hasMore;
  bool get isLoading;

  /// Called once from the home screen; guards against duplicate initialisations.
  Future<void> init();

  /// Loads the next page, or refreshes from page 0 when [refresh] is true.
  Future<void> loadProducts({bool refresh = false});

  Future<void> selectCategory(String category);
  Future<void> search(String query);
  void clearSearch();
  void setSort(SortOption option);
}

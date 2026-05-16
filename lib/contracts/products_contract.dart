import '../models/product.dart';

enum LoadState { idle, loading, loaded, error }

enum SortOption { none, priceLow, priceHigh, ratingHigh }

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

abstract class IProductsPresenter {
  List<Product> get products;
  List<Product> get deals;
  List<String> get categories;
  String get selectedCategory;
  String get searchQuery;
  SortOption get sortOption;
  LoadState get state;
  String get errorMessage;
  bool get hasMore;
  bool get isLoading;

  Future<void> init();
  Future<void> loadProducts({bool refresh = false});
  Future<void> selectCategory(String category);
  Future<void> search(String query);
  void clearSearch();
  void setSort(SortOption option);
}

import 'package:flutter/foundation.dart';
import '../contracts/products_contract.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

/// Manages the product catalog: pagination, category filter, search, and sort.
///
/// Architecture notes:
///   - Extends [ChangeNotifier] so Provider can propagate state to the UI.
///   - Implements [IProductsPresenter] to keep the View decoupled from this
///     concrete class and allow easy test injection.
///   - [_deals] is computed once per load and cached — not recomputed on
///     every widget rebuild — to avoid an O(n) sort on every paint frame.
class ProductsPresenter extends ChangeNotifier implements IProductsPresenter {
  final ProductRepository _repository;

  List<Product> _products = [];
  List<Product> _filtered = [];
  List<Product> _deals = [];
  List<String> _categories = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  SortOption _sortOption = SortOption.none;
  LoadState _state = LoadState.idle;
  String _errorMessage = '';
  bool _hasMore = true;
  int _skip = 0;
  static const _limit = 30;

  ProductsPresenter({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  @override
  List<Product> get products => _filtered;

  @override
  List<Product> get deals => _deals;

  /// Prepends 'all' so the category chip row always shows an "All" chip first.
  @override
  List<String> get categories => ['all', ..._categories];

  @override
  String get selectedCategory => _selectedCategory;

  @override
  String get searchQuery => _searchQuery;

  @override
  SortOption get sortOption => _sortOption;

  @override
  LoadState get state => _state;

  @override
  String get errorMessage => _errorMessage;

  @override
  bool get hasMore => _hasMore;

  @override
  bool get isLoading => _state == LoadState.loading;

  /// Entry point called once by [HomeScreen.initState] via addPostFrameCallback.
  /// The guard prevents a second init if the widget rebuilds before the first
  /// load completes (e.g. hot reload during a slow network request).
  @override
  Future<void> init() async {
    if (_state == LoadState.loaded || _state == LoadState.loading) return;
    await _loadCategories();
    await loadProducts(refresh: true);
  }

  /// Fetches categories silently; a failure here is non-fatal — the chip row
  /// simply stays empty and the user can still browse all products.
  Future<void> _loadCategories() async {
    try {
      _categories = await _repository.getCategories();
    } catch (e) {
      debugPrint('[ProductsPresenter] Failed to load categories: $e');
    }
  }

  @override
  Future<void> loadProducts({bool refresh = false}) async {
    // Prevent concurrent loads — the scroll listener fires many times per second.
    if (_state == LoadState.loading) return;
    if (refresh) {
      _skip = 0;
      _products = [];
      _hasMore = true;
    }
    if (!_hasMore) return;

    _state = LoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      List<Product> fetched;
      if (_searchQuery.isNotEmpty) {
        fetched = await _repository.searchProducts(_searchQuery);
        // Search returns all matches at once; disable further pagination.
        _hasMore = false;
      } else if (_selectedCategory != 'all') {
        fetched = await _repository.getProductsByCategory(_selectedCategory,
            limit: _limit);
        _hasMore = false;
      } else {
        fetched = await _repository.getProducts(limit: _limit, skip: _skip);
        _skip += fetched.length;
        // A partial page means we've reached the end of the catalogue.
        if (fetched.length < _limit) _hasMore = false;
      }

      if (refresh) {
        _products = fetched;
      } else {
        _products.addAll(fetched);
      }

      // Apply sort before exposing to the UI.
      _filtered = _applySorting(_products);

      // Build deals list: products with ≥15% discount, sorted by discount desc.
      _deals = _products.where((p) => p.discountPercentage >= 15).toList()
        ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));

      _state = LoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }

  @override
  Future<void> selectCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _searchQuery = '';
    await loadProducts(refresh: true);
  }

  @override
  Future<void> search(String query) async {
    _searchQuery = query;
    _selectedCategory = 'all';
    await loadProducts(refresh: true);
  }

  @override
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    loadProducts(refresh: true);
  }

  /// Sort is applied in-memory to the already-fetched list — no extra API call.
  @override
  void setSort(SortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _filtered = _applySorting(_products);
    notifyListeners();
  }

  /// Returns a new sorted list; never mutates [_products] so the original
  /// order is preserved and switching back to "Default" is instant.
  List<Product> _applySorting(List<Product> list) {
    final sorted = List<Product>.from(list);
    switch (_sortOption) {
      case SortOption.priceLow:
        sorted.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
      case SortOption.priceHigh:
        sorted.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
      case SortOption.ratingHigh:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.none:
        break;
    }
    return sorted;
  }
}

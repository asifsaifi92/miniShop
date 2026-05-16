import 'package:flutter/foundation.dart';
import '../contracts/products_contract.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductsPresenter extends ChangeNotifier implements IProductsPresenter {
  final ProductRepository _repository;

  List<Product> _products = [];
  List<Product> _filtered = [];
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
  List<Product> get deals =>
      _products.where((p) => p.discountPercentage >= 15).toList()
        ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));

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

  @override
  Future<void> init() async {
    if (_state == LoadState.loaded) return;
    await _loadCategories();
    await loadProducts(refresh: true);
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _repository.getCategories();
    } catch (e) {
      debugPrint('[ProductsPresenter] Failed to load categories: $e');
    }
  }

  @override
  Future<void> loadProducts({bool refresh = false}) async {
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
        _hasMore = false;
      } else if (_selectedCategory != 'all') {
        fetched = await _repository.getProductsByCategory(_selectedCategory,
            limit: _limit);
        _hasMore = false;
      } else {
        fetched = await _repository.getProducts(limit: _limit, skip: _skip);
        _skip += fetched.length;
        if (fetched.length < _limit) _hasMore = false;
      }

      if (refresh) {
        _products = fetched;
      } else {
        _products.addAll(fetched);
      }

      _filtered = _applySorting(_products);
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

  @override
  void setSort(SortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _filtered = _applySorting(_products);
    notifyListeners();
  }

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

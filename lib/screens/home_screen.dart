import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contracts/products_contract.dart';
import '../presenters/products_presenter.dart';
import '../presenters/cart_presenter.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/deals_section.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsPresenter>().init();
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductsPresenter>().loadProducts();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      context.read<ProductsPresenter>().clearSearch();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProductsPresenter>().search(query.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductsPresenter>(
        builder: (_, provider, _) => CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(context),
            const SliverToBoxAdapter(child: ConnectivityBanner()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildCategoryChips(provider)),
            if (provider.deals.isNotEmpty)
              const SliverToBoxAdapter(child: DealsSection()),
            SliverToBoxAdapter(child: _buildSectionHeader(context, provider)),
            ..._buildProductContent(provider),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('MiniShop'),
        ],
      ),
      actions: [
        Selector<CartPresenter, int>(
          selector: (_, cart) => cart.itemCount,
          builder: (_, count, _) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CartScreen())),
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 8,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey(count),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle),
                      child: Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WishlistScreen())),
        ),
        Selector<ProductsPresenter, SortOption>(
          selector: (_, p) => p.sortOption,
          builder: (_, sort, _) => IconButton(
            icon: Icon(Icons.tune_rounded,
                color: sort != SortOption.none
                    ? Colors.amber
                    : Colors.white),
            tooltip: 'Sort',
            onPressed: () => SortBottomSheet.show(context),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OrdersScreen())),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search products, brands...',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: Colors.grey.shade400),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: Colors.grey.shade400),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ProductsPresenter>().clearSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ProductsPresenter provider) {
    if (provider.categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        itemCount: provider.categories.length,
        itemBuilder: (_, i) {
          final cat = provider.categories[i];
          final selected = provider.selectedCategory == cat;
          final label = cat == 'all'
              ? 'All'
              : cat
                  .replaceAll('-', ' ')
                  .split(' ')
                  .map((w) =>
                      w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
                  .join(' ');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                    _debounce?.cancel();
                    _searchController.clear();
                    provider.selectCategory(cat);
                  },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary,
              showCheckmark: false,
              elevation: selected ? 0 : 1,
              shadowColor: Colors.black12,
              side: BorderSide.none,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, ProductsPresenter provider) {
    if (provider.products.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final label = provider.searchQuery.isNotEmpty
        ? '"${provider.searchQuery}"'
        : provider.selectedCategory != 'all'
            ? provider.selectedCategory
                .replaceAll('-', ' ')
                .split(' ')
                .map((w) =>
                    w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
                .join(' ')
            : 'All Products';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${provider.products.length}${provider.hasMore ? '+' : ''} items',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (provider.sortOption != SortOption.none)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded, size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    provider.sortOption.label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildProductContent(ProductsPresenter provider) {
    if (provider.state == LoadState.loading && provider.products.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          sliver: SliverGrid(
            gridDelegate: _kGridDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, _) => const SkeletonProductCard(),
              childCount: 6,
            ),
          ),
        ),
      ];
    }
    if (provider.state == LoadState.error && provider.products.isEmpty) {
      return [
        SliverFillRemaining(
          child: ErrorView(
            message: provider.errorMessage,
            onRetry: () => provider.loadProducts(refresh: true),
          ),
        ),
      ];
    }
    if (provider.state == LoadState.loaded && provider.products.isEmpty) {
      return [
        const SliverFillRemaining(
          child: EmptyView(
            message: 'No products found.\nTry a different search or category.',
            icon: Icons.search_off_rounded,
          ),
        ),
      ];
    }

    final total = provider.products.length +
        (provider.hasMore && provider.state == LoadState.loading ? 2 : 0);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        sliver: SliverGrid(
          gridDelegate: _kGridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= provider.products.length) {
                return const SkeletonProductCard();
              }
              return _EntranceCard(
                key: ValueKey(provider.products[i].id),
                index: i,
                child: ProductCard(product: provider.products[i]),
              );
            },
            childCount: total,
          ),
        ),
      ),
    ];
  }

  static const _kGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.62,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
  );
}

// ─────────────────────────────────────────
// Staggered entrance animation wrapper
// ─────────────────────────────────────────
class _EntranceCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _EntranceCard(
      {required this.index, required this.child, super.key});

  @override
  State<_EntranceCard> createState() => _EntranceCardState();
}

class _EntranceCardState extends State<_EntranceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = widget.index < 8
        ? Duration(milliseconds: widget.index * 55)
        : Duration.zero;
    delay == Duration.zero
        ? _ctrl.forward()
        : Future.delayed(delay, () {
            if (mounted) _ctrl.forward();
          });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

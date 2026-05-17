import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presenters/wishlist_presenter.dart';
import '../widgets/product_card.dart';
import '../widgets/error_view.dart';

/// Grid of all wishlisted products. Uses the same [ProductCard] as the home
/// screen so the heart-toggle and add-to-cart behaviour are identical.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: Consumer<WishlistPresenter>(
        builder: (_, wl, _) {
          if (wl.items.isEmpty) {
            return const EmptyView(
              message: 'No saved items yet.\nTap the heart icon to save!',
              icon: Icons.favorite_border,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            // cacheExtent pre-renders cards up to 600 px outside the viewport
            // to reduce blank flashes while scrolling.
            cacheExtent: 600,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: wl.items.length,
            itemBuilder: (_, i) => ProductCard(product: wl.items[i]),
          );
        },
      ),
    );
  }
}

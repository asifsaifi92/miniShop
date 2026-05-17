import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../presenters/cart_presenter.dart';
import '../presenters/wishlist_presenter.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12,
                                  color: Colors.amber.shade600),
                              const SizedBox(width: 3),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          _buildPrice(colorScheme),
                        ],
                      ),
                      _buildCartButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        Hero(
          tag: 'product-img-${product.id}',
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CachedNetworkImage(
              imageUrl: product.thumbnail,
              fit: BoxFit.cover,
              placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (_, _, _) =>
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          ),
        ),
        if (product.hasDiscount)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-${product.discountPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Selector<WishlistPresenter, bool>(
            selector: (_, wl) => wl.contains(product.id),
            builder: (ctx, inWishlist, _) => GestureDetector(
              onTap: () => ctx.read<WishlistPresenter>().toggle(product),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    inWishlist ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(inWishlist),
                    size: 16,
                    color: inWishlist ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrice(ColorScheme cs) {
    if (product.hasDiscount) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '\$${product.discountedPrice.toStringAsFixed(2)}',
            style: TextStyle(
                color: cs.primary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(
      '\$${product.price.toStringAsFixed(2)}',
      style: TextStyle(
          color: cs.primary, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Selector<CartPresenter, bool>(
      selector: (_, cart) => cart.contains(product.id),
      builder: (ctx, inCart, _) => _CartButton(
        inCart: inCart,
        onAdd: () => ctx.read<CartPresenter>().addProduct(product),
        onRemove: () => ctx.read<CartPresenter>().removeProduct(product.id),
      ),
    );
  }
}

class _CartButton extends StatefulWidget {
  final bool inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartButton(
      {required this.inCart,
      required this.onAdd,
      required this.onRemove});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1, end: 0.88)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.inCart ? widget.onRemove() : widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: double.infinity,
        height: 30,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.inCart
              ? OutlinedButton.icon(
                  key: const ValueKey('added'),
                  onPressed: _onTap,
                  icon: const Icon(Icons.check, size: 14),
                  label:
                      const Text('Added', style: TextStyle(fontSize: 12)),
                )
              : FilledButton.icon(
                  key: const ValueKey('add'),
                  onPressed: _onTap,
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                      minimumSize: Size.zero, padding: EdgeInsets.zero),
                ),
        ),
      ),
    );
  }
}

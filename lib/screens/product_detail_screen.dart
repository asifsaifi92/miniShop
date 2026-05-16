import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../presenters/cart_presenter.dart';
import '../presenters/wishlist_presenter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImage = 0;
  late final Future<List<Product>> _similarFuture;

  Product get p => widget.product;

  @override
  void initState() {
    super.initState();
    _similarFuture = ApiService()
        .getProductsByCategory(p.category, limit: 10)
        .then((list) => list.where((item) => item.id != p.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Consumer<WishlistPresenter>(
            builder: (_, wl, _) => IconButton(
              icon: Icon(
                wl.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                color: wl.contains(p.id) ? Colors.red : Colors.white,
              ),
              onPressed: () => wl.toggle(p),
            ),
          ),
          Consumer<CartPresenter>(
            builder: (_, cart, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageGallery(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategory(),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildRating(),
                        const SizedBox(height: 12),
                        _buildPrice(colorScheme),
                        const SizedBox(height: 12),
                        _buildStock(),
                        const Divider(height: 24),
                        const Text(
                          'Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.description,
                          style: TextStyle(
                              height: 1.5, color: Colors.grey.shade700),
                        ),
                        if (p.brand.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Brand', p.brand),
                        ],
                        _buildInfoRow('Category',
                            p.category.replaceAll('-', ' ').toUpperCase()),
                      ],
                    ),
                  ),
                  _buildSimilarProducts(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = p.images.isNotEmpty ? p.images : [p.thumbnail];
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: Hero(
            tag: 'product-img-${p.id}',
            child: CachedNetworkImage(
              imageUrl: images[_selectedImage],
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, _, _) =>
                  const Center(child: Icon(Icons.broken_image, size: 64)),
            ),
          ),
        ),
        if (p.hasDiscount)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${p.discountPercentage.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (images.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: images.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedImage = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImage == i
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        RatingBarIndicator(
          rating: p.rating,
          itemBuilder: (_, _) =>
              const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 18,
        ),
        const SizedBox(width: 6),
        Text(
          '${p.rating.toStringAsFixed(1)} / 5.0',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPrice(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${p.discountedPrice.toStringAsFixed(2)}',
          style: TextStyle(
              color: cs.primary, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        if (p.hasDiscount) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '\$${p.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStock() {
    final low = p.stock < 10;
    return Row(
      children: [
        Icon(
          low ? Icons.warning_amber : Icons.check_circle,
          size: 16,
          color: low ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          low ? 'Only ${p.stock} left' : 'In Stock (${p.stock})',
          style: TextStyle(
              color: low ? Colors.orange : Colors.green, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        p.category.replaceAll('-', ' ').toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return FutureBuilder<List<Product>>(
      future: _similarFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'You May Also Like',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: item),
                      ),
                    ),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: CachedNetworkImage(
                              imageUrl: item.thumbnail,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '\$${item.discountedPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Consumer<CartPresenter>(
      builder: (_, cart, _) {
        final inCart = cart.contains(p.id);
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Row(
            children: [
              if (inCart) ...[
                _qtyButton(
                    icon: Icons.remove,
                    onTap: () => cart.decrement(p.id)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${cart.quantityOf(p.id)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _qtyButton(
                    icon: Icons.add, onTap: () => cart.increment(p.id)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (inCart) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartScreen()));
                    } else {
                      cart.addProduct(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to cart!'),
                          duration: const Duration(seconds: 1),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen())),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(inCart
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart),
                  label: Text(inCart ? 'Go to Cart' : 'Add to Cart'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

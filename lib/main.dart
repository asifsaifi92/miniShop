import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenters/cart_presenter.dart';
import 'presenters/products_presenter.dart';
import 'presenters/wishlist_presenter.dart';
import 'presenters/orders_presenter.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MiniShopApp());
}

/// Root widget. All presenters are created here so they remain alive for the
/// entire app lifetime and are accessible from any descendant widget.
class MiniShopApp extends StatelessWidget {
  const MiniShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ProductsPresenter owns catalog, search, category filter, and sort state.
        ChangeNotifierProvider(create: (_) => ProductsPresenter()),
        // CartPresenter persists cart to SharedPreferences on every mutation.
        ChangeNotifierProvider(create: (_) => CartPresenter()),
        // WishlistPresenter persists wishlist to SharedPreferences on every mutation.
        ChangeNotifierProvider(create: (_) => WishlistPresenter()),
        // OrdersPresenter persists order history to SharedPreferences.
        ChangeNotifierProvider(create: (_) => OrdersPresenter()),
      ],
      child: MaterialApp(
        title: 'MiniShop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}

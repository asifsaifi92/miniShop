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

class MiniShopApp extends StatelessWidget {
  const MiniShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsPresenter()),
        ChangeNotifierProvider(create: (_) => CartPresenter()),
        ChangeNotifierProvider(create: (_) => WishlistPresenter()),
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

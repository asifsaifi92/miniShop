import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MiniShopApp());

    // Splash screen is immediately visible
    expect(find.text('MiniShop'), findsWidgets);

    // Advance fake time past:
    //   2 600 ms  → splash delay fires, navigates to HomeScreen
    //  10 000 ms  → HTTP timeout fires (relative to request start), presenter
    //               moves to error state and no more timers remain
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
  });
}

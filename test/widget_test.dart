import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MiniShopApp());
    expect(find.text('MiniShop'), findsOneWidget);
  });
}

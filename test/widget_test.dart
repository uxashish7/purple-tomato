import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VirtualTradingApp(),
      ),
    );
    expect(find.byType(VirtualTradingApp), findsOneWidget);
  });
}

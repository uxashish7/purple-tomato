import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/features/market/widgets/trade_execution_sheet.dart';

void main() {
  final testStock = Stock(
    instrumentKey: 'NSE_EQ|RELIANCE',
    symbol: 'RELIANCE',
    name: 'Reliance Industries',
    exchange: 'NSE',
    instrumentType: 'EQUITY',
  );

  testWidgets('TradeExecutionSheet renders stock symbol and total price accurately', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TradeExecutionSheet(
              stock: testStock,
              livePrice: 2500.0,
            ),
          ),
        ),
      ),
    );

    // Verify BUY RELIANCE button is rendered
    expect(find.text('BUY RELIANCE'), findsOneWidget);
    expect(find.text('BUY'), findsWidgets);
    expect(find.text('SELL'), findsOneWidget);

    // Verify price rendering
    expect(find.text('₹2500.00'), findsWidgets);
  });
}

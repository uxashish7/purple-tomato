import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/core/services/upstox_service.dart';

void main() {
  group('UpstoxService Tests', () {
    late UpstoxService upstoxService;

    setUp(() {
      upstoxService = UpstoxService();
    });

    test('searchStocks with empty query returns top 10 mock stocks', () async {
      // In mock mode (not authenticated), it should return mock results
      final results = await upstoxService.searchStocks('');
      
      expect(results, isNotEmpty);
      expect(results.length, 10);
      expect(results.first.symbol, 'RELIANCE');
    });

    test('searchStocks with query returns filtered mock stocks', () async {
      final results = await upstoxService.searchStocks('hdfc');
      
      expect(results, isNotEmpty);
      final symbols = results.map((e) => e.symbol).toList();
      expect(symbols.contains('HDFCBANK'), isTrue);
      expect(symbols.contains('HDFCLIFE'), isTrue);
    });

    test('getLiveQuotes returns mock quotes for given instruments', () async {
      final instrumentKeys = ['NSE_EQ|INE002A01018', 'NSE_EQ|INE467B01029'];
      final quotes = await upstoxService.getLiveQuotes(instrumentKeys);
      
      expect(quotes.length, 2);
      expect(quotes.containsKey('NSE_EQ|INE002A01018'), isTrue);
      expect(quotes.containsKey('NSE_EQ|INE467B01029'), isTrue);
      
      final relQuote = quotes['NSE_EQ|INE002A01018'];
      expect(relQuote?.instrumentKey, 'NSE_EQ|INE002A01018');
      // The exact price depends on if market is open, but it shouldn't be null
      expect(relQuote?.lastPrice, isNotNull);
    });

    test('getIndexQuotes returns mock indices', () async {
      final indices = await upstoxService.getIndexQuotes();
      
      expect(indices.length, 2);
      final names = indices.map((e) => e.name).toList();
      expect(names.contains('NIFTY 50'), isTrue);
      expect(names.contains('SENSEX'), isTrue);
    });
  });
}

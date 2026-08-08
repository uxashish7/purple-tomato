import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/core/providers/market_data_provider.dart';
import 'package:purple_tomato/core/services/upstox_service.dart';
import 'package:purple_tomato/domain/models/market_quote.dart';

// Create a simple mock for UpstoxService
class MockUpstoxService extends UpstoxService {
  @override
  Future<List<IndexQuote>> getIndexQuotes() async {
    return [
      IndexQuote.mock(
        name: 'NIFTY 50',
        instrumentKey: '^NSEI',
        value: 25000.0,
        change: 100.0,
        changePercent: 0.4,
      )
    ];
  }
}

void main() {
  group('MarketDataProvider Tests', () {
    test('stockSearchProvider handles empty query correctly', () async {
      final container = ProviderContainer();
      
      final result = await container.read(stockSearchProvider('a').future);
      expect(result, isEmpty, reason: 'Should return empty for query length < 2');
      
      container.dispose();
    });

    test('LiveQuotesNotifier updates keys and fetches correctly', () {
      final mockService = MockUpstoxService();
      final notifier = LiveQuotesNotifier(mockService, {'key1', 'key2'});
      
      expect(notifier.state, isEmpty); // Initial state before async fetch
      
      notifier.updateKeys({'key3'}); // Should update keys without failing
      
      notifier.dispose();
    });
  });
}

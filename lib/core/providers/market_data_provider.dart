import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_quote.dart';
import '../services/upstox_service.dart';
import '../services/yahoo_finance_service.dart';
import '../config/api_config.dart';
import 'watchlist_provider.dart';
import 'portfolio_provider.dart';

/// Provider for Upstox service instance
final upstoxServiceProvider = Provider<UpstoxService>((ref) {
  return UpstoxService();
});

/// Provider for Yahoo Finance service instance
final yahooFinanceServiceProvider = Provider<YahooFinanceService>((ref) {
  return YahooFinanceService();
});

/// Provider for index quotes (Nifty 50, Sensex)
/// Uses mock data directly for reliability - always shows indices
final indexQuotesProvider = FutureProvider<List<IndexQuote>>((ref) async {
  // Always return mock data immediately for reliability
  // These values will be updated when live APIs are connected
  final mockData = [
    IndexQuote.mock(name: 'NIFTY 50', instrumentKey: '^NSEI', value: 26178.70, change: 146.55, changePercent: 0.56),
    IndexQuote.mock(name: 'SENSEX', instrumentKey: '^BSESN', value: 85063.34, change: 478.29, changePercent: 0.57),
  ];
  
  // Try to get live data in background but always return mock first
  final yahooService = ref.watch(yahooFinanceServiceProvider);
  
  try {
    final quotes = await yahooService.getIndices().timeout(
      const Duration(seconds: 5),
      onTimeout: () => mockData,
    );
    if (quotes.isNotEmpty && quotes.first.value > 0) {
      print('Using Yahoo Finance for index data');
      return quotes;
    }
  } catch (e) {
    print('Yahoo Finance failed, using mock data: $e');
  }
  
  print('Using mock index data');
  return mockData;
});

/// Provider for live market quotes
/// Combines watchlist and portfolio stocks for live price updates
final liveQuotesProvider = StateNotifierProvider<LiveQuotesNotifier, Map<String, MarketQuote>>((ref) {
  final service = ref.watch(upstoxServiceProvider);
  final watchlist = ref.watch(watchlistProvider);
  final holdings = ref.watch(portfolioProvider);
  
  // Combine instrument keys from watchlist and portfolio
  final watchlistKeys = watchlist.map((s) => s.instrumentKey).toSet();
  final holdingKeys = holdings.map((h) => h.stock.instrumentKey).toSet();
  final allKeys = {...watchlistKeys, ...holdingKeys};
  
  return LiveQuotesNotifier(service, allKeys.toList());
});

/// Live quotes state notifier with polling
class LiveQuotesNotifier extends StateNotifier<Map<String, MarketQuote>> {
  final UpstoxService _service;
  final List<String> _instrumentKeys;
  Timer? _pollingTimer;

  LiveQuotesNotifier(this._service, this._instrumentKeys) : super({}) {
    if (_instrumentKeys.isNotEmpty) {
      _fetchQuotes(); // Initial fetch
      _startPolling();
    }
  }

  void _startPolling() {
    if (!ApiConfig.enableLivePolling) return;
    
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: ApiConfig.pricePollingIntervalSeconds),
      (_) => _fetchQuotes(),
    );
  }

  Future<void> _fetchQuotes() async {
    if (_instrumentKeys.isEmpty) return;
    
    try {
      final quotes = await _service.getLiveQuotes(_instrumentKeys);
      if (mounted) {
        state = quotes;
      }
    } catch (e) {
      print('Error fetching live quotes: $e');
    }
  }

  /// Force refresh quotes
  Future<void> refresh() async {
    await _fetchQuotes();
  }

  /// Get quote for a specific instrument
  MarketQuote? getQuote(String instrumentKey) {
    return state[instrumentKey];
  }

  /// Get live price for a specific instrument
  double getLivePrice(String instrumentKey) {
    return state[instrumentKey]?.lastPrice ?? 0;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Provider for live prices map (just prices, not full quotes)
final livePricesProvider = Provider<Map<String, double>>((ref) {
  final quotes = ref.watch(liveQuotesProvider);
  return quotes.map((key, quote) => MapEntry(key, quote.lastPrice));
});

/// Provider to get live price for a specific stock
final stockPriceProvider = Provider.family<double?, String>((ref, instrumentKey) {
  final quotes = ref.watch(liveQuotesProvider);
  return quotes[instrumentKey]?.lastPrice;
});

/// Provider for stock search
final stockSearchProvider = FutureProvider.family.autoDispose<List, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];
  
  final service = ref.watch(upstoxServiceProvider);
  return service.searchStocks(query);
});

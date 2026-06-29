import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/domain/models/market_quote.dart';
import '../services/upstox_service.dart';
import '../services/yahoo_finance_service.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';
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
/// Uses Yahoo Finance with mock fallback for reliability.
final indexQuotesProvider = FutureProvider<List<IndexQuote>>((ref) async {
  final mockData = [
    IndexQuote.mock(name: 'NIFTY 50', instrumentKey: '^NSEI', value: 26178.70, change: 146.55, changePercent: 0.56),
    IndexQuote.mock(name: 'SENSEX', instrumentKey: '^BSESN', value: 85063.34, change: 478.29, changePercent: 0.57),
  ];

  final yahooService = ref.watch(yahooFinanceServiceProvider);

  try {
    final quotes = await yahooService.getIndices().timeout(
      const Duration(seconds: 5),
      onTimeout: () => mockData,
    );
    if (quotes.isNotEmpty && quotes.first.value > 0) {
      AppLogger.info('Using Yahoo Finance for index data', tag: 'MarketData');
      return quotes;
    }
  } catch (e) {
    AppLogger.warn('Yahoo Finance failed, using mock data', tag: 'MarketData', error: e);
  }

  AppLogger.info('Using mock index data', tag: 'MarketData');
  return mockData;
});

/// Provider for live market quotes.
/// Passes the current key-set to [LiveQuotesNotifier].
/// The notifier itself tracks changes and avoids timer recreation on minor rebuilds.
final liveQuotesProvider = StateNotifierProvider<LiveQuotesNotifier, Map<String, MarketQuote>>((ref) {
  final service = ref.watch(upstoxServiceProvider);
  final watchlist = ref.watch(watchlistProvider);
  final holdings = ref.watch(portfolioProvider);

  final watchlistKeys = watchlist.map((s) => s.instrumentKey).toSet();
  final holdingKeys = holdings.map((h) => h.stock.instrumentKey).toSet();
  final allKeys = {...watchlistKeys, ...holdingKeys};

  return LiveQuotesNotifier(service, allKeys);
});

/// Live quotes state notifier with polling.
///
/// Timer lifecycle:
/// • Started once on construction.
/// • Cancelled and restarted only when the instrument key-set actually changes,
///   preventing timer multiplication on every Riverpod rebuild.
class LiveQuotesNotifier extends StateNotifier<Map<String, MarketQuote>> {
  final UpstoxService _service;
  Set<String> _instrumentKeys;
  Timer? _pollingTimer;

  LiveQuotesNotifier(this._service, Set<String> instrumentKeys)
      : _instrumentKeys = instrumentKeys,
        super({}) {
    if (_instrumentKeys.isNotEmpty) {
      _fetchQuotes();
      _startPolling();
    }
  }

  /// Update the instrument keys without recreating the entire notifier.
  /// Only restarts polling if the key-set has changed.
  void updateKeys(Set<String> newKeys) {
    if (newKeys.length == _instrumentKeys.length &&
        newKeys.every(_instrumentKeys.contains)) {
      return; // No change — keep existing timer
    }
    _instrumentKeys = newKeys;
    if (_instrumentKeys.isNotEmpty) {
      _fetchQuotes();
      _restartPolling();
    } else {
      _pollingTimer?.cancel();
      _pollingTimer = null;
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

  void _restartPolling() {
    _pollingTimer?.cancel();
    _startPolling();
  }

  Future<void> _fetchQuotes() async {
    if (_instrumentKeys.isEmpty) return;

    try {
      final quotes = await _service.getLiveQuotes(_instrumentKeys.toList());
      if (mounted) {
        state = quotes;
      }
    } catch (e) {
      AppLogger.warn('Error fetching live quotes', tag: 'MarketData', error: e);
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

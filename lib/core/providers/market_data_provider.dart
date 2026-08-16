import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/domain/models/market_quote.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import '../services/upstox_service.dart';
import '../services/yahoo_finance_service.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'watchlist_provider.dart';
import 'portfolio_provider.dart';

/// Single shared Upstox service instance used by ALL providers.
/// Previously, upstoxAuthProvider created a separate UpstoxService instance
/// which meant auth and market data were fully disconnected (Bug #1 fix).
final upstoxServiceProvider = Provider<UpstoxService>((ref) {
  return UpstoxService();
});

/// Provider for Yahoo Finance service instance
final yahooFinanceServiceProvider = Provider<YahooFinanceService>((ref) {
  return YahooFinanceService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Index Quotes — auto-polling every 5 s (Bug #5 fix: was a one-shot FutureProvider)
// ─────────────────────────────────────────────────────────────────────────────

class IndexQuotesNotifier extends StateNotifier<AsyncValue<List<IndexQuote>>> {
  final UpstoxService _upstox;
  final YahooFinanceService _yahoo;
  Timer? _timer;

  IndexQuotesNotifier(this._upstox, this._yahoo)
      : super(const AsyncValue.loading()) {
    _fetch();
    if (ApiConfig.enableLivePolling) {
      _timer = Timer.periodic(
        Duration(seconds: ApiConfig.pricePollingIntervalSeconds),
        (_) => _fetch(),
      );
    }
  }

  Future<void> _fetch() async {
    try {
      if (await _upstox.isAuthenticated) {
        final quotes = await _upstox.getIndexQuotes();
        if (quotes.isNotEmpty && quotes.any((q) => q.value > 0)) {
          AppLogger.info('Using Upstox API for live index data', tag: 'MarketData');
          if (mounted) state = AsyncValue.data(quotes);
          return;
        }
      }
    } catch (e) {
      AppLogger.warn('Upstox index fetch failed', tag: 'MarketData', error: e);
    }

    try {
      final quotes = await _yahoo.getIndices().timeout(const Duration(seconds: 5));
      if (quotes.isNotEmpty && quotes.first.value > 0) {
        AppLogger.info('Using Yahoo Finance for index data', tag: 'MarketData');
        if (mounted) state = AsyncValue.data(quotes);
        return;
      }
    } catch (e) {
      AppLogger.warn('Yahoo Finance index fetch failed', tag: 'MarketData', error: e);
    }

    AppLogger.info('Using mock index data', tag: 'MarketData');
    final mockData = [
      IndexQuote.mock(
          name: 'NIFTY 50',
          instrumentKey: ApiConfig.nifty50Key,
          value: 26178.70,
          change: 146.55,
          changePercent: 0.56),
      IndexQuote.mock(
          name: 'SENSEX',
          instrumentKey: ApiConfig.sensexKey,
          value: 85063.34,
          change: 478.29,
          changePercent: 0.57),
    ];
    if (mounted) state = AsyncValue.data(mockData);
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final indexQuotesProvider =
    StateNotifierProvider<IndexQuotesNotifier, AsyncValue<List<IndexQuote>>>((ref) {
  final upstox = ref.watch(upstoxServiceProvider);
  final yahoo = ref.watch(yahooFinanceServiceProvider);
  return IndexQuotesNotifier(upstox, yahoo);
});

// ─────────────────────────────────────────────────────────────────────────────
// Live Quotes — additive key management, never loses keys (Bug #2, #3 fix)
// ─────────────────────────────────────────────────────────────────────────────

final liveQuotesProvider =
    StateNotifierProvider<LiveQuotesNotifier, Map<String, MarketQuote>>((ref) {
  final service = ref.watch(upstoxServiceProvider);

  // Use ref.read (not watch) so the notifier is NOT recreated every time
  // watchlist or portfolio changes — those screens call addKeys/updateKeys
  // on the existing notifier instead.
  final watchlist = ref.read(watchlistProvider);
  final holdings = ref.read(portfolioProvider);

  final initialKeys = <String>{
    ...watchlist.map((s) => s.instrumentKey),
    ...holdings.map((h) => h.stock.instrumentKey),
  };

  return LiveQuotesNotifier(service, initialKeys);
});

/// Live quotes state notifier with polling.
class LiveQuotesNotifier extends StateNotifier<Map<String, MarketQuote>> {
  final UpstoxService _service;
  Set<String> _instrumentKeys;
  Timer? _pollingTimer;

  LiveQuotesNotifier(this._service, Set<String> instrumentKeys)
      : _instrumentKeys = Set.from(instrumentKeys),
        super({}) {
    if (_instrumentKeys.isNotEmpty) _fetchQuotes();
    _startPolling();
  }

  /// Add keys additively — existing keys are NOT removed.
  /// Use from search / popular-stocks screens.
  void addKeys(Set<String> newKeys) {
    final added = newKeys.where((k) => !_instrumentKeys.contains(k)).toSet();
    if (added.isEmpty) return;
    _instrumentKeys = {..._instrumentKeys, ...added};
    _fetchQuotes();
  }

  /// Replace the full key-set (e.g. after watchlist or portfolio change).
  void updateKeys(Set<String> newKeys) {
    final changed = newKeys.length != _instrumentKeys.length ||
        !newKeys.every(_instrumentKeys.contains);
    if (!changed) return;
    _instrumentKeys = Set.from(newKeys);
    if (_instrumentKeys.isNotEmpty) _fetchQuotes();
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
      final quotes = await _service.getLiveQuotes(_instrumentKeys.toList());
      if (mounted && quotes.isNotEmpty) {
        state = {...state, ...quotes}; // Merge, don't replace
      }
    } catch (e) {
      AppLogger.warn('Error fetching live quotes', tag: 'MarketData', error: e);
    }
  }

  Future<void> refresh() => _fetchQuotes();
  MarketQuote? getQuote(String instrumentKey) => state[instrumentKey];
  double getLivePrice(String instrumentKey) => state[instrumentKey]?.lastPrice ?? 0;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Live prices map (prices only)
final livePricesProvider = Provider<Map<String, double>>((ref) {
  final quotes = ref.watch(liveQuotesProvider);
  return quotes.map((key, quote) => MapEntry(key, quote.lastPrice));
});

/// Live price for a specific stock
final stockPriceProvider = Provider.family<double?, String>((ref, instrumentKey) {
  final quotes = ref.watch(liveQuotesProvider);
  return quotes[instrumentKey]?.lastPrice;
});

// ─────────────────────────────────────────────────────────────────────────────
// Stock Search — results with live LTP (Bug #4 fix)
// ─────────────────────────────────────────────────────────────────────────────

/// Search result enriched with live price data from Upstox LTP API.
class StockSearchResult {
  final Stock stock;
  final double? lastPrice;
  final double? changePercent;

  const StockSearchResult({
    required this.stock,
    this.lastPrice,
    this.changePercent,
  });

  bool get hasLivePrice => lastPrice != null;
}

/// Stock search with immediate live LTP fetch for each result.
final stockSearchProvider =
    FutureProvider.family.autoDispose<List<StockSearchResult>, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];

  final service = ref.watch(upstoxServiceProvider);

  // 1. Match stocks from local master list
  final stocks = await service.searchStocks(query);
  if (stocks.isEmpty) return [];

  // 2. Register keys with the live quotes notifier for ongoing polling
  final keys = stocks.map((s) => s.instrumentKey).toSet();
  ref.read(liveQuotesProvider.notifier).addKeys(keys);

  // 3. Fetch live LTP directly so prices appear immediately in search results
  Map<String, MarketQuote> quotes = {};
  try {
    if (await service.isAuthenticated) {
      debugPrint('StockSearch: Fetching live LTP for ${keys.length} stocks');
      quotes = await service.getLiveQuotes(keys.toList());
      debugPrint('StockSearch: Got ${quotes.length} live quotes');
    }
  } catch (e) {
    debugPrint('StockSearch: LTP fetch failed — $e');
  }

  return stocks.map((stock) {
    final quote = quotes[stock.instrumentKey];
    return StockSearchResult(
      stock: stock,
      lastPrice: quote?.lastPrice,
      changePercent: quote?.changePercent,
    );
  }).toList();
});




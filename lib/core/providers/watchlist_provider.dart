import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock.dart';
import '../services/hive_service.dart';

/// Watchlist state notifier
class WatchlistNotifier extends StateNotifier<List<Stock>> {
  WatchlistNotifier() : super(HiveService.getWatchlist());

  /// Add stock to watchlist
  Future<void> add(Stock stock) async {
    if (!isInWatchlist(stock.instrumentKey)) {
      await HiveService.addToWatchlist(stock);
      state = HiveService.getWatchlist();
    }
  }

  /// Remove stock from watchlist
  Future<void> remove(String instrumentKey) async {
    await HiveService.removeFromWatchlist(instrumentKey);
    state = HiveService.getWatchlist();
  }

  /// Toggle stock in watchlist
  Future<void> toggle(Stock stock) async {
    if (isInWatchlist(stock.instrumentKey)) {
      await remove(stock.instrumentKey);
    } else {
      await add(stock);
    }
  }

  /// Check if stock is in watchlist
  bool isInWatchlist(String instrumentKey) {
    return state.any((s) => s.instrumentKey == instrumentKey);
  }

  /// Get all instrument keys in watchlist
  List<String> get instrumentKeys {
    return state.map((s) => s.instrumentKey).toList();
  }

  /// Refresh from storage
  void refresh() {
    state = HiveService.getWatchlist();
  }
}

/// Provider for watchlist state
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<Stock>>((ref) {
  return WatchlistNotifier();
});

/// Provider to check if a specific stock is in watchlist
final isInWatchlistProvider = Provider.family<bool, String>((ref, instrumentKey) {
  final watchlist = ref.watch(watchlistProvider);
  return watchlist.any((s) => s.instrumentKey == instrumentKey);
});

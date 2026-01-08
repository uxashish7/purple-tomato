import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/watchlist_provider.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/stock_tile.dart';
import 'stock_detail_screen.dart';
import 'stock_search_screen.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final quotes = ref.watch(liveQuotesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: watchlist.isEmpty
          ? _buildEmptyState(context)
          : _buildWatchlist(context, ref, watchlist, quotes),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            color: AppTheme.textMuted.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No stocks in watchlist',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add stocks to track their prices',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockSearchScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Stocks'),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlist(
    BuildContext context,
    WidgetRef ref,
    List watchlist,
    Map quotes,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: watchlist.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 76,
        color: AppTheme.cardElevated,
      ),
      itemBuilder: (context, index) {
        final stock = watchlist[index];
        final quote = quotes[stock.instrumentKey];

        return Dismissible(
          key: Key(stock.instrumentKey),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppTheme.lossRed,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(watchlistProvider.notifier).remove(stock.instrumentKey);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${stock.symbol} removed from watchlist'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    ref.read(watchlistProvider.notifier).add(stock);
                  },
                ),
              ),
            );
          },
          child: StockTile(
            stock: stock,
            price: quote?.lastPrice,
            change: quote?.change,
            changePercent: quote?.changePercent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockDetailScreen(stock: stock),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

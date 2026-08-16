import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/core/providers/market_data_provider.dart';
import 'package:purple_tomato/core/providers/watchlist_provider.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:purple_tomato/core/constants/route_names.dart';
import 'package:intl/intl.dart';

class StockSearchScreen extends ConsumerStatefulWidget {
  const StockSearchScreen({super.key});

  @override
  ConsumerState<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends ConsumerState<StockSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  // Popular stocks for display when no search query
  final List<Map<String, dynamic>> _popularStocks = [
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'key': 'NSE_EQ|INE002A01018', 'price': 2427.79, 'change': -0.91},
    {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'key': 'NSE_EQ|INE467B01029', 'price': 3860.71, 'change': 0.28},
    {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'key': 'NSE_EQ|INE040A01034', 'price': 1654.90, 'change': 0.30},
    {'symbol': 'INFY', 'name': 'Infosys', 'key': 'NSE_EQ|INE009A01021', 'price': 1498.06, 'change': -1.44},
    {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'key': 'NSE_EQ|INE090A01021', 'price': 1175.02, 'change': -0.42},
  ];

  // Top Gainers
  final List<Map<String, dynamic>> _topGainers = [
    {'symbol': 'SBIN', 'name': 'State Bank of India', 'key': 'NSE_EQ|INE081A01020', 'price': 790.28, 'change': 2.85},
    {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'key': 'NSE_EQ|INE066A01029', 'price': 1580.45, 'change': 2.12},
    {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'key': 'NSE_EQ|INE001A01036', 'price': 785.60, 'change': 1.95},
    {'symbol': 'ADANIENT', 'name': 'Adani Enterprises', 'key': 'NSE_EQ|INE917I01010', 'price': 2450.30, 'change': 1.78},
    {'symbol': 'HINDALCO', 'name': 'Hindalco Industries', 'key': 'NSE_EQ|INE012A01025', 'price': 625.40, 'change': 1.65},
  ];

  // Top Losers
  final List<Map<String, dynamic>> _topLosers = [
    {'symbol': 'WIPRO', 'name': 'Wipro Limited', 'key': 'NSE_EQ|INE018A01030', 'price': 452.30, 'change': -2.45},
    {'symbol': 'TECHM', 'name': 'Tech Mahindra', 'key': 'NSE_EQ|INE079A01024', 'price': 1285.60, 'change': -2.12},
    {'symbol': 'DRREDDY', 'name': "Dr. Reddy's Labs", 'key': 'NSE_EQ|INE030A01027', 'price': 1180.40, 'change': -1.88},
    {'symbol': 'APOLLOHOSP', 'name': 'Apollo Hospitals', 'key': 'NSE_EQ|INE114A01011', 'price': 6250.75, 'change': -1.65},
    {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance', 'key': 'NSE_EQ|INE155A01022', 'price': 6890.20, 'change': -1.42},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keys = <String>{
        ..._popularStocks.map((s) => s['key'] as String),
        ..._topGainers.map((s) => s['key'] as String),
        ..._topLosers.map((s) => s['key'] as String),
      };
      ref.read(liveQuotesProvider.notifier).updateKeys(keys);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(stockSearchProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Search Stocks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by symbol or name...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildPopularStocks()
                : _buildSearchResults(searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularStocks() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular Stocks Section
          _buildStockSection('Popular Stocks', _popularStocks, Icons.star, isPopular: true),
          const SizedBox(height: 24),
          
          // Top Gainers Section
          _buildStockSection('Top Gainers', _topGainers, Icons.trending_up, isGainer: true),
          const SizedBox(height: 24),
          
          // Top Losers Section
          _buildStockSection('Top Losers', _topLosers, Icons.trending_down, isLoser: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStockSection(String title, List<Map<String, dynamic>> stocks, IconData icon, {bool isGainer = false, bool isLoser = false, bool isPopular = false}) {
    Color iconColor = AppTheme.textMuted;
    if (isPopular) iconColor = const Color(0xFFFFD700); // Golden Yellow
    if (isGainer) iconColor = AppTheme.profitGreen;
    if (isLoser) iconColor = AppTheme.lossRed;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...stocks.map((stock) => _PopularStockTile(
          symbol: stock['symbol'] as String,
          name: stock['name'] as String,
          instrumentKey: stock['key'] as String,
          defaultPrice: stock['price'] as double,
          defaultChangePercent: stock['change'] as double,
          onTap: () {
            final stockObj = Stock(
              instrumentKey: stock['key'] as String,
              symbol: stock['symbol'] as String,
              name: stock['name'] as String,
              exchange: 'NSE',
              instrumentType: 'EQ',
            );
            context.pushNamed(
              RouteNames.stockDetail,
              pathParameters: {'symbol': stockObj.symbol},
              extra: stockObj,
            );
          },
        )),
      ],
    );
  }


  Widget _buildSearchResults(AsyncValue<List<dynamic>> searchResults) {
    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return _buildNoResults();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index] as StockSearchResult;
            final stock = result.stock;
            final isInWatchlist = ref.watch(isInWatchlistProvider(stock.instrumentKey));

            return _SearchResultTile(
              stock: stock,
              isInWatchlist: isInWatchlist,
              lastPrice: result.lastPrice,
              changePercent: result.changePercent,
              onTap: () {
                context.pushNamed(
                  RouteNames.stockDetail,
                  pathParameters: {'symbol': stock.symbol},
                  extra: stock,
                );
              },
              onWatchlistTap: () {
                ref.read(watchlistProvider.notifier).toggle(stock);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInWatchlist
                          ? '${stock.symbol} removed from watchlist'
                          : '${stock.symbol} added to watchlist',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentBlue),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.lossRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Search error',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(stockSearchProvider(_searchQuery)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: AppTheme.textMuted.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No stocks found',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularStockTile extends ConsumerWidget {
  final String symbol;
  final String name;
  final String instrumentKey;
  final double defaultPrice;
  final double defaultChangePercent;
  final VoidCallback onTap;

  const _PopularStockTile({
    required this.symbol,
    required this.name,
    required this.instrumentKey,
    required this.defaultPrice,
    required this.defaultChangePercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveQuotes = ref.watch(liveQuotesProvider);
    final quote = liveQuotes[instrumentKey];

    final price = quote?.lastPrice ?? defaultPrice;
    final changePercent = quote?.changePercent ?? defaultChangePercent;

    final isPositive = changePercent >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol.length >= 2 ? symbol.substring(0, 2) : symbol,
                  style: const TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Stock stock;
  final bool isInWatchlist;
  final double? lastPrice;
  final double? changePercent;
  final VoidCallback onTap;
  final VoidCallback onWatchlistTap;

  const _SearchResultTile({
    required this.stock,
    required this.isInWatchlist,
    required this.onTap,
    required this.onWatchlistTap,
    this.lastPrice,
    this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrice = lastPrice != null;
    final isPositive = (changePercent ?? 0) >= 0;
    final priceColor = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stock.symbol.length >= 2 ? stock.symbol.substring(0, 2) : stock.symbol,
                  style: const TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.symbol,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Price column (live if available)
            if (hasPrice)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20b9${fmt.format(lastPrice)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent!.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: priceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            // Watchlist toggle
            IconButton(
              icon: Icon(
                isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
                color: isInWatchlist ? AppTheme.accentBlue : AppTheme.textMuted,
              ),
              onPressed: onWatchlistTap,
            ),
          ],
        ),
      ),
    );
  }
}

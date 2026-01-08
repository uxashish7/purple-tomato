import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/stock.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/providers/watchlist_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'stock_detail_screen.dart';

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
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'price': 2427.79, 'change': -0.91},
    {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'price': 3860.71, 'change': 0.28},
    {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'price': 1654.90, 'change': 0.30},
    {'symbol': 'INFY', 'name': 'Infosys', 'price': 1498.06, 'change': -1.44},
    {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'price': 1175.02, 'change': -0.42},
  ];

  // Top Gainers
  final List<Map<String, dynamic>> _topGainers = [
    {'symbol': 'SBIN', 'name': 'State Bank of India', 'price': 790.28, 'change': 2.85},
    {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'price': 1580.45, 'change': 2.12},
    {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'price': 785.60, 'change': 1.95},
    {'symbol': 'ADANIENT', 'name': 'Adani Enterprises', 'price': 2450.30, 'change': 1.78},
    {'symbol': 'HINDALCO', 'name': 'Hindalco Industries', 'price': 625.40, 'change': 1.65},
  ];

  // Top Losers
  final List<Map<String, dynamic>> _topLosers = [
    {'symbol': 'WIPRO', 'name': 'Wipro Limited', 'price': 452.30, 'change': -2.45},
    {'symbol': 'TECHM', 'name': 'Tech Mahindra', 'price': 1285.60, 'change': -2.12},
    {'symbol': 'DRREDDY', 'name': "Dr. Reddy's Labs", 'price': 1180.40, 'change': -1.88},
    {'symbol': 'APOLLOHOSP', 'name': 'Apollo Hospitals', 'price': 6250.75, 'change': -1.65},
    {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance', 'price': 6890.20, 'change': -1.42},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
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
          onPressed: () => Navigator.pop(context),
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
          price: stock['price'] as double,
          changePercent: stock['change'] as double,
          onTap: () {
            final mockStock = Stock(
              instrumentKey: '${stock['symbol']}.NS',
              symbol: stock['symbol'] as String,
              name: stock['name'] as String,
              exchange: 'NSE',
              instrumentType: 'EQ',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockDetailScreen(stock: mockStock),
              ),
            );
          },
        )),
      ],
    );
  }


  Widget _buildSearchResults(AsyncValue<List<dynamic>> searchResults) {
    return searchResults.when(
      data: (stocks) {
        if (stocks.isEmpty) {
          return _buildNoResults();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index] as Stock;
            final isInWatchlist = ref.watch(isInWatchlistProvider(stock.instrumentKey));
            
            return _SearchResultTile(
              stock: stock,
              isInWatchlist: isInWatchlist,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockDetailScreen(stock: stock),
                  ),
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
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.lossRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to search stocks',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
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

class _PopularStockTile extends StatelessWidget {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final VoidCallback onTap;

  const _PopularStockTile({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  symbol.substring(0, 2),
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
  final VoidCallback onTap;
  final VoidCallback onWatchlistTap;

  const _SearchResultTile({
    required this.stock,
    required this.isInWatchlist,
    required this.onTap,
    required this.onWatchlistTap,
  });

  @override
  Widget build(BuildContext context) {
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
            // Watchlist button
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

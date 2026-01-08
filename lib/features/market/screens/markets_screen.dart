import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/models/stock.dart';
import '../../../shared/theme/app_theme.dart';
import 'stock_search_screen.dart';
import 'stock_detail_screen.dart';

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexQuotes = ref.watch(indexQuotesProvider);

    // Mock data for top gainers/losers (will be populated from API later)
    final topGainers = [
      {'symbol': 'HINDUNILVR', 'name': 'Hindustan Unilever', 'price': 2424.46, 'change': 1.87},
      {'symbol': 'INFY', 'name': 'Infosys', 'price': 1547.90, 'change': 1.84},
      {'symbol': 'TCS', 'name': 'Tata Consultancy', 'price': 3874.11, 'change': 1.52},
      {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'price': 1654.90, 'change': 0.85},
    ];

    final topLosers = [
      {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'price': 2427.79, 'change': -0.91},
      {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'price': 1175.02, 'change': -0.42},
      {'symbol': 'SBIN', 'name': 'State Bank of India', 'price': 790.28, 'change': -0.32},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Markets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isMarketOpen() ? AppTheme.profitGreen : AppTheme.textTertiary,
                    shape: BoxShape.circle,
                    boxShadow: _isMarketOpen() ? [
                      BoxShadow(
                        color: AppTheme.profitGreen.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ] : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isMarketOpen() ? 'NSE Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isMarketOpen() ? AppTheme.profitGreen : AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockSearchScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(indexQuotesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Market Indices Section
              const Text(
                'Market Indices',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              indexQuotes.when(
                data: (indices) {
                  return Column(
                    children: indices.map((index) {
                      final isPositive = index.change >= 0;
                      final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.cardElevated,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  index.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  index.name == 'NIFTY 50' ? 'NSE' : 'BSE',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  index.value.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        color: color,
                                        size: 16,
                                      ),
                                      Text(
                                        '${isPositive ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Failed to load', style: TextStyle(color: AppTheme.lossRed)),
              ),
              
              const SizedBox(height: 24),
              
              // Top Gainers
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppTheme.profitGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Gainers',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ...topGainers.map((stock) => _StockListItem(
                symbol: stock['symbol'] as String,
                name: stock['name'] as String,
                price: stock['price'] as double,
                changePercent: stock['change'] as double,
              )),
              
              const SizedBox(height: 24),
              
              // Top Losers
              Row(
                children: [
                  Icon(Icons.trending_down, color: AppTheme.lossRed, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Losers',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ...topLosers.map((stock) => _StockListItem(
                symbol: stock['symbol'] as String,
                name: stock['name'] as String,
                price: stock['price'] as double,
                changePercent: stock['change'] as double,
              )),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  bool _isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    
    // Market open on weekdays 9:15 AM - 3:30 PM IST
    if (weekday >= 6) return false; // Weekend
    if (hour < 9 || (hour == 9 && minute < 15)) return false;
    if (hour > 15 || (hour == 15 && minute > 30)) return false;
    
    return true;
  }
}

class _StockListItem extends StatelessWidget {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;

  const _StockListItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

    return GestureDetector(
      onTap: () {
        // Create a Stock object and navigate to detail screen
        final stock = Stock(
          instrumentKey: 'NSE_EQ|$symbol',
          symbol: symbol,
          name: name,
          exchange: 'NSE',
          instrumentType: 'EQUITY',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(stock: stock),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  symbol.substring(0, 2),
                  style: TextStyle(
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
                      fontSize: 14,
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
                    fontSize: 14,
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

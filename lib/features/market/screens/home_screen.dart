import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:purple_tomato/core/providers/wallet_provider.dart';
import 'package:purple_tomato/core/providers/portfolio_provider.dart';
import 'package:purple_tomato/core/providers/market_data_provider.dart';
import 'package:purple_tomato/core/providers/upstox_auth_provider.dart';
import 'package:purple_tomato/core/services/hive_service.dart';
import 'package:purple_tomato/core/services/supabase_service.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';
import '../widgets/portfolio_value_card.dart';
import '../widgets/market_index_card.dart';
import '../widgets/portfolio_allocation_section.dart';
import '../widgets/recent_transactions_section.dart';

import 'package:purple_tomato/shared/widgets/common/mock_mode_banner.dart';
import 'package:purple_tomato/shared/widgets/charts/portfolio_chart.dart';
import '../../portfolio/screens/portfolio_screen.dart';
import '../../portfolio/screens/transactions_screen.dart';
import '../../advisor/screens/advisor_screen.dart';
import 'stock_search_screen.dart';
import 'watchlist_screen.dart';
import 'markets_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:purple_tomato/core/constants/route_names.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeContent(),
          PortfolioScreen(),
          AdvisorScreen(),
          TransactionsScreen(),
          WatchlistScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppTheme.cardElevated.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'AI Advisor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Watchlist',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  String _formatIndianCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Check if Indian stock market is open (uses IST timezone)
  bool _isMarketOpen() {
    // Force IST timezone (UTC+5:30) regardless of device timezone
    final utcNow = DateTime.now().toUtc();
    final istNow = utcNow.add(const Duration(hours: 5, minutes: 30));
    
    final hour = istNow.hour;
    final minute = istNow.minute;
    final weekday = istNow.weekday;
    
    // Market open on weekdays 9:15 AM - 3:30 PM IST
    if (weekday >= 6) return false; // Weekend (Saturday=6, Sunday=7)
    if (hour < 9 || (hour == 9 && minute < 15)) return false;
    if (hour > 15 || (hour == 15 && minute > 30)) return false;
    
    return true;
  }

  /// Generate simulated portfolio history for chart
  List<double> _generatePortfolioHistory(double initialValue, double currentValue) {
    // Generate 7 data points simulating daily portfolio values
    final List<double> history = [];
    final diff = currentValue - initialValue;
    
    for (int i = 0; i <= 6; i++) {
      // Simulate a somewhat realistic growth curve with minor fluctuations
      final progress = i / 6.0;
      final variation = (i % 2 == 0 ? 0.02 : -0.01) * initialValue;
      final value = initialValue + (diff * progress) + variation;
      history.add(value);
    }
    
    // Ensure last value matches current
    history[6] = currentValue;
    return history;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final holdings = ref.watch(portfolioProvider);
    final livePrices = ref.watch(livePricesProvider);
    final isMockMode = ref.watch(isMockModeProvider);
    final indexQuotes = ref.watch(indexQuotesProvider);

    // Calculate portfolio values
    double investedValue = 0;
    double currentValue = 0;
    for (final holding in holdings) {
      investedValue += holding.investedValue;
      final livePrice = livePrices[holding.stock.instrumentKey] ?? holding.avgBuyPrice;
      currentValue += holding.quantity * livePrice;
    }
    
    final totalPortfolioValue = wallet.balance + currentValue;
    final overallPnL = totalPortfolioValue - wallet.initialBalance;
    final overallPnLPercent = wallet.initialBalance > 0 
        ? (overallPnL / wallet.initialBalance) * 100 
        : 0.0;

    // Save portfolio snapshot to Supabase (rate-limited to once per hour)
    SupabaseService.saveSnapshotIfNeeded(
      totalValue: totalPortfolioValue,
      cashBalance: wallet.balance,
      investedAmount: investedValue,
      holdingsValue: currentValue,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.whatshot, 
                color: AppTheme.accentPurple,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Purple Tomato',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.invalidate(indexQuotesProvider);
            },
          ),
          // Market status indicator
          Container(
            margin: const EdgeInsets.only(right: 8, left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDefault,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isMarketOpen() ? AppTheme.profitGreen : AppTheme.lossRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isMarketOpen() ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: _isMarketOpen() ? AppTheme.profitGreen : AppTheme.lossRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(indexQuotesProvider);
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Demo mode banner — visible only when running without live data
              const MockModeBanner(),

              // Search Bar linked to Stock Search
              GestureDetector(
                onTap: () {
                  context.pushNamed(RouteNames.stockSearch);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark, // Lighter than background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderDefault.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search stocks, indices...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Portfolio Value Card
              PortfolioValueCard(
                totalValue: totalPortfolioValue,
                overallPnL: overallPnL,
                overallPnLPercent: overallPnLPercent,
                availableCash: wallet.balance,
                investedValue: investedValue,
                currentValue: currentValue,
              ),
              
              const SizedBox(height: 24),
              
              // Market Indices
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
                  if (indices.isEmpty) {
                    return const Text('No index data', style: TextStyle(color: AppTheme.textMuted));
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: MarketIndexCard(
                            name: indices[0].name,
                            value: indices[0].value,
                            change: indices[0].change,
                            changePercent: indices[0].changePercent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (indices.length > 1)
                          Expanded(
                            child: MarketIndexCard(
                              name: indices[1].name,
                              value: indices[1].value,
                              change: indices[1].change,
                              changePercent: indices[1].changePercent,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => Row(
                  children: [
                    Expanded(child: MarketIndexCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: MarketIndexCardShimmer()),
                  ],
                ),
                error: (_, __) => const Text(
                  'Failed to load indices',
                  style: TextStyle(color: AppTheme.lossRed),
                ),
              ),
              
              // Portfolio Allocation (if holdings exist)
              if (holdings.isNotEmpty) ...[
                const SizedBox(height: 24),
                PortfolioAllocationSection(
                  holdings: holdings,
                  livePrices: livePrices,
                  totalValue: currentValue,
                ),
              ],
              
              // Portfolio Performance Chart
              const SizedBox(height: 24),
              PortfolioChart(
                values: _generatePortfolioHistory(wallet.initialBalance, totalPortfolioValue),
                labels: const ['Start', 'Now'],
                startValue: wallet.initialBalance,
                currentValue: totalPortfolioValue,
                hasHoldings: holdings.isNotEmpty,
                investedAmount: investedValue,
                holdingsValue: currentValue,
              ),
              
              const SizedBox(height: 24),
              
              // Recent Transactions
              RecentTransactionsSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}

// Portfolio Value Card with summary stats - Modern Glassmorphism Design

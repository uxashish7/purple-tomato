import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/providers/upstox_auth_provider.dart';
import '../../../core/services/hive_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/portfolio_chart.dart';
import '../../portfolio/screens/portfolio_screen.dart';
import '../../portfolio/screens/transactions_screen.dart';
import '../../advisor/screens/advisor_screen.dart';
import 'stock_search_screen.dart';
import 'watchlist_screen.dart';
import 'markets_screen.dart';

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

  /// Check if Indian stock market is open
  bool _isMarketOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar linked to Stock Search
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockSearchScreen()),
                  );
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
              _PortfolioValueCard(
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
                          child: _IndexCard(
                            name: indices[0].name,
                            value: indices[0].value,
                            change: indices[0].change,
                            changePercent: indices[0].changePercent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (indices.length > 1)
                          Expanded(
                            child: _IndexCard(
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
                    Expanded(child: _IndexCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _IndexCardShimmer()),
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
                _PortfolioAllocationSection(
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
              ),
              
              const SizedBox(height: 24),
              
              // Recent Transactions
              _RecentTransactionsSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Portfolio Value Card with summary stats - Modern Glassmorphism Design
class _PortfolioValueCard extends StatefulWidget {
  final double totalValue;
  final double overallPnL;
  final double overallPnLPercent;
  final double availableCash;
  final double investedValue;
  final double currentValue;

  const _PortfolioValueCard({
    required this.totalValue,
    required this.overallPnL,
    required this.overallPnLPercent,
    required this.availableCash,
    required this.investedValue,
    required this.currentValue,
  });

  @override
  State<_PortfolioValueCard> createState() => _PortfolioValueCardState();
}

class _PortfolioValueCardState extends State<_PortfolioValueCard> {
  bool _isHidden = false;

  String _formatCompact(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)} K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  String _hideValue(String value) {
    return _isHidden ? '₹••••••' : value;
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.overallPnL >= 0;
    final pnlColor = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Glassmorphism effect
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with privacy toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total Portfolio Value',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Privacy toggle
                  GestureDetector(
                    onTap: () => setState(() => _isHidden = !_isHidden),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDefault,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _isHidden ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              // PnL Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: pnlColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isHidden ? '••••' : '${isPositive ? '+' : ''}${widget.overallPnLPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Total Value
          Text(
            _hideValue(_formatCompact(widget.totalValue)),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.5,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Overall P&L
          Text(
            _isHidden ? '•••• overall' : '${isPositive ? '+' : ''}${_formatCompact(widget.overallPnL)} overall',
            style: TextStyle(
              color: pnlColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Summary Stats Row with prominent background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Very dark blue-black for better contrast than pure black
              color: const Color(0xFF12121A), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2A2A35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Cash',
                    value: _hideValue(_formatCompact(widget.availableCash)),
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.borderSubtle),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    label: 'Invested',
                    value: _hideValue(_formatCompact(widget.investedValue)),
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.borderSubtle),
                Expanded(
                  child: _StatItem(
                    icon: Icons.show_chart,
                    label: 'Current',
                    value: _hideValue(_formatCompact(widget.currentValue)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentBlue.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF82B1FF), // Brighter blue for visibility
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Index Card with Glassmorphism - Clean vertical layout
class _IndexCard extends StatelessWidget {
  final String name;
  final double value;
  final double change;
  final double changePercent;

  const _IndexCard({
    required this.name,
    required this.value,
    required this.change,
    required this.changePercent,
  });

  String _formatValue(double val) {
    if (val >= 100000) {
      return val.toStringAsFixed(0);
    }
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Index name
          Text(
            name,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Value - large and prominent
          Text(
            _formatValue(value),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Change badge - pill style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
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
    );
  }
}

class _IndexCardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.cardElevated,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 80,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.cardElevated,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Portfolio Allocation Section with Donut Chart
class _PortfolioAllocationSection extends StatelessWidget {
  final List holdings;
  final Map<String, double> livePrices;
  final double totalValue;

  const _PortfolioAllocationSection({
    required this.holdings,
    required this.livePrices,
    required this.totalValue,
  });

  static const List<Color> _colors = [
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF2196F3), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portfolio Allocation',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    holdings: holdings,
                    livePrices: livePrices,
                    totalValue: totalValue,
                    colors: _colors,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    holdings.length > 4 ? 4 : holdings.length,
                    (index) {
                      final holding = holdings[index];
                      final price = livePrices[holding.stock.instrumentKey] ?? holding.avgBuyPrice;
                      final value = holding.quantity * price;
                      final percent = totalValue > 0 ? (value / totalValue) * 100 : 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colors[index % _colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                holding.stock.symbol,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List holdings;
  final Map<String, double> livePrices;
  final double totalValue;
  final List<Color> colors;

  _DonutChartPainter({
    required this.holdings,
    required this.livePrices,
    required this.totalValue,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 20.0;
    
    double startAngle = -1.5708; // Start from top (-90 degrees in radians)
    
    for (int i = 0; i < holdings.length; i++) {
      final holding = holdings[i];
      final price = livePrices[holding.stock.instrumentKey] ?? holding.avgBuyPrice;
      final value = holding.quantity * price;
      final percent = totalValue > 0 ? value / totalValue : 0;
      final sweepAngle = percent * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Recent Transactions Section
class _RecentTransactionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = HiveService.getOrders();
    final recentOrders = orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        if (recentOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppTheme.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start trading to see your history',
                    style: TextStyle(
                      color: AppTheme.textMuted.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: recentOrders.map((order) {
                final isBuy = order.isBuy;  // Use the proper getter
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isBuy ? AppTheme.profitGreen : AppTheme.lossRed).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isBuy ? AppTheme.profitGreen : AppTheme.lossRed,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    order.stock.symbol,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${isBuy ? 'HOLDING' : 'SOLD'} • ${order.quantity} shares',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${order.timestamp.hour}:${order.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing dot indicator for live market status
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.addListener(() {
      setState(() {});
    });
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(_animation.value * 0.6),
            blurRadius: 6 * _animation.value,
            spreadRadius: 2 * _animation.value,
          ),
        ],
      ),
    );
  }
}

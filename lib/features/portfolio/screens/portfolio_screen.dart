import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/pnl_display.dart';
import '../../market/screens/stock_detail_screen.dart';
import '../../market/screens/stock_search_screen.dart';
import 'transactions_screen.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(portfolioProvider);
    final livePrices = ref.watch(livePricesProvider);
    final wallet = ref.watch(walletProvider);

    final totalInvested = holdings.fold(0.0, (sum, h) => sum + h.investedValue);
    final totalCurrent = holdings.fold(0.0, (sum, h) {
      final livePrice = livePrices[h.stock.instrumentKey] ?? h.avgBuyPrice;
      return sum + h.currentValue(livePrice);
    });
    final totalPnl = totalCurrent - totalInvested;
    final totalPnlPercent = totalInvested > 0 ? (totalPnl / totalInvested) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Portfolio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Transaction History - clear receipt icon
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary),
            tooltip: 'Transaction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              );
            },
          ),
        ],
      ),
      body: holdings.isEmpty
          ? _buildEmptyState(context)
          : _buildPortfolio(context, ref, holdings, livePrices, totalInvested, totalCurrent, totalPnl, totalPnlPercent, wallet),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline,
              color: AppTheme.textMuted.withOpacity(0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No holdings yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buy stocks to build your portfolio',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockSearchScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Buy Stocks', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio(
    BuildContext context,
    WidgetRef ref,
    List holdings,
    Map<String, double> livePrices,
    double totalInvested,
    double totalCurrent,
    double totalPnl,
    double totalPnlPercent,
    wallet,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(portfolioProvider.notifier).refresh();
        ref.invalidate(liveQuotesProvider);
      },
      color: AppTheme.accentBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // P&L Summary Card - Premium Design
            PnlCard(
              totalPnl: totalPnl,
              pnlPercent: totalPnlPercent,
              investedValue: totalInvested,
              currentValue: totalCurrent,
            ),
            
            const SizedBox(height: 16),
            
            // Available Cash Card - Glassmorphism
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Available Cash',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(wallet.balance)}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Holdings Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Holdings',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${holdings.length} stocks',
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Holdings List - Premium Cards
            ...holdings.map((holding) {
              final livePrice = livePrices[holding.stock.instrumentKey] ?? holding.avgBuyPrice;
              final pnl = holding.pnlAmount(livePrice);
              final pnlPercent = holding.pnlPercent(livePrice);
              final isPositive = pnl >= 0;
              final pnlColor = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(stock: holding.stock),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Row
                          Row(
                            children: [
                              // Stock Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.accentBlue.withOpacity(0.2),
                                      AppTheme.accentBlue.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    holding.stock.symbol.substring(0, 2),
                                    style: const TextStyle(
                                      color: AppTheme.accentBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // Stock Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      holding.stock.symbol,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${holding.quantity} shares @ ₹${holding.avgBuyPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Value & P&L
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${_formatCompact(holding.currentValue(livePrice))}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: pnlColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: pnlColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 14),
                          
                          // Stats Row - Clean Design
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _buildStatItem('Invested', '₹${_formatCompact(holding.investedValue)}'),
                                _divider(),
                                _buildStatItem('LTP', '₹${livePrice.toStringAsFixed(0)}'),
                                _divider(),
                                _buildStatItem(
                                  'P&L',
                                  '${isPositive ? '+' : ''}₹${_formatCompact(pnl.abs())}',
                                  valueColor: pnlColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  
  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
  
  String _formatCompact(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

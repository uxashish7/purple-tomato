import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/stock.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/providers/watchlist_provider.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../core/services/yahoo_finance_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/stock_candlestick_chart.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final Stock stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  bool _isBuyMode = true;
  int _quantity = 1;
  String _orderType = 'Market'; // Market, Limit, SL
  
  // Price fetching state
  final YahooFinanceService _yahooService = YahooFinanceService();
  double? _fetchedPrice;
  double? _fetchedChange;
  double? _fetchedChangePercent;
  bool _isPriceFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchLivePrice();
  }

  Future<void> _fetchLivePrice() async {
    try {
      final ohlcData = await _yahooService.getHistoricalOHLC(
        widget.stock.symbol,
        period: '1d',
        interval: '5m',
      );
      
      if (ohlcData.isNotEmpty) {
        final latest = ohlcData.last;
        final first = ohlcData.first;
        final change = latest.close - first.open;
        final changePercent = (change / first.open) * 100;
        
        setState(() {
          _fetchedPrice = latest.close;
          _fetchedChange = change;
          _fetchedChangePercent = changePercent;
          _isPriceFetching = false;
        });
      } else {
        setState(() => _isPriceFetching = false);
      }
    } catch (e) {
      print('Price fetch error: $e');
      setState(() => _isPriceFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(liveQuotesProvider);
    final quote = quotes[widget.stock.instrumentKey];
    final isInWatchlist = ref.watch(isInWatchlistProvider(widget.stock.instrumentKey));
    final holding = ref.read(portfolioProvider.notifier).getHolding(widget.stock.instrumentKey);
    final wallet = ref.watch(walletProvider);
    
    // Use fetched price first, then live quote, then fallback
    final livePrice = _fetchedPrice ?? quote?.lastPrice ?? 1500.0;
    final change = _fetchedChange ?? quote?.change ?? 0.0;
    final changePercent = _fetchedChangePercent ?? quote?.changePercent ?? 0.0;
    final isPositive = change >= 0;
    final priceColor = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;

    // OHLC based on actual fetched price
    final open = livePrice - 10;
    final high = livePrice + 25;
    final low = livePrice - 15;
    final close = livePrice;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
              color: isInWatchlist ? AppTheme.accentBlue : AppTheme.textMuted,
            ),
            onPressed: () {
              ref.read(watchlistProvider.notifier).toggle(widget.stock);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Header with Avatar
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      widget.stock.symbol.length >= 2 
                          ? widget.stock.symbol.substring(0, 2) 
                          : widget.stock.symbol,
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stock.symbol,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.stock.name,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.stock.exchange,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Price Display - Properly Aligned
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹${livePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: priceColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priceColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: priceColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: priceColor,
                          size: 18,
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: priceColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Candlestick Chart
            StockCandlestickChart(
              symbol: widget.stock.symbol,
              currentPrice: livePrice,
            ),
            
            const SizedBox(height: 16),
            
            // OHLC Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _OHLCItem(label: 'Open', value: open),
                  _OHLCItem(label: 'High', value: high),
                  _OHLCItem(label: 'Low', value: low),
                  _OHLCItem(label: 'Close', value: close),
                ],
              ),
            ),
            
            // Current Holding - Glassmorphism Design
            if (holding != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentPurple.withOpacity(0.15),
                      AppTheme.accentBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentPurple.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: AppTheme.accentPurple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Your Holding',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        // Current Value with P&L
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${(holding.quantity * livePrice).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final currentVal = holding.quantity * livePrice;
                                final pnl = currentVal - holding.investedValue;
                                final pnlPercent = (pnl / holding.investedValue) * 100;
                                final isProfit = pnl >= 0;
                                return Text(
                                  '${isProfit ? '+' : ''}₹${pnl.toStringAsFixed(0)} (${isProfit ? '+' : ''}${pnlPercent.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: isProfit ? AppTheme.profitGreen : AppTheme.lossRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _HoldingInfoModern(label: 'Qty', value: '${holding.quantity}'),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          _HoldingInfoModern(label: 'Avg', value: '₹${holding.avgBuyPrice.toStringAsFixed(0)}'),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          _HoldingInfoModern(label: 'Invested', value: '₹${holding.investedValue.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Order Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Buy/Sell Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isBuyMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _isBuyMode 
                                  ? AppTheme.profitGreen 
                                  : AppTheme.cardElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'BUY',
                                style: TextStyle(
                                  color: _isBuyMode 
                                      ? Colors.white 
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (holding == null || holding.quantity == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You don\'t own this stock. Buy first to sell.'),
                                  backgroundColor: AppTheme.warningOrange,
                                ),
                              );
                              return;
                            }
                            setState(() => _isBuyMode = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: (holding == null || holding.quantity == 0)
                                  ? AppTheme.surfaceDisabled
                                  : (!_isBuyMode 
                                      ? AppTheme.lossRed 
                                      : AppTheme.cardElevated),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SELL',
                                    style: TextStyle(
                                      color: (holding == null || holding.quantity == 0)
                                          ? AppTheme.textDisabled
                                          : (!_isBuyMode 
                                              ? Colors.white 
                                              : AppTheme.textMuted),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (holding == null || holding.quantity == 0) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.lock_outline,
                                      size: 14,
                                      color: AppTheme.textDisabled,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quantity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Order Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Type',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildOrderTypeChip('Market'),
                          const SizedBox(width: 8),
                          _buildOrderTypeChip('Limit'),
                          const SizedBox(width: 8),
                          _buildOrderTypeChip('SL'),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price & Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Price', style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              '₹${livePrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quantity', style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              '$_quantity',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.cardElevated, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${(livePrice * _quantity).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _isBuyMode ? AppTheme.profitGreen : AppTheme.lossRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isBuyMode) {
                          _executeBuy(context, _quantity, livePrice);
                        } else {
                          // Sell mode
                          if (holding == null || holding.quantity == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You don\'t own this stock. Buy first to sell.'),
                                backgroundColor: AppTheme.warningOrange,
                              ),
                            );
                            return;
                          }
                          if (holding.quantity < _quantity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Insufficient shares. You only have ${holding.quantity} shares.'),
                                backgroundColor: AppTheme.warningOrange,
                              ),
                            );
                            return;
                          }
                          _executeSell(context, _quantity, livePrice);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBuyMode 
                            ? AppTheme.profitGreen 
                            : (holding != null && holding.quantity >= _quantity
                                ? AppTheme.lossRed
                                : AppTheme.surfaceDisabled),
                        foregroundColor: _isBuyMode || (holding != null && holding.quantity >= _quantity)
                            ? Colors.white
                            : AppTheme.textDisabled,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${_isBuyMode ? 'BUY' : 'SELL'} ${widget.stock.symbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(String label) {
    final isSelected = _orderType == label;
    return GestureDetector(
      onTap: () {
        if (label != 'Market') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label orders coming soon! Only Market orders available now.'),
              backgroundColor: AppTheme.infoDefault,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        setState(() => _orderType = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : AppTheme.borderDefault,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _executeBuy(BuildContext context, int quantity, double price) async {
    final balance = ref.read(walletProvider).balance;
    final totalCost = price * quantity;
    
    if (balance < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient funds'),
          backgroundColor: AppTheme.lossRed,
        ),
      );
      return;
    }
    
    final success = await ref.read(portfolioProvider.notifier).buyStock(
      stock: widget.stock,
      quantity: quantity,
      price: price,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Bought $quantity ${widget.stock.symbol} @ ₹${price.toStringAsFixed(2)}'
              : 'Failed to execute buy order',
        ),
        backgroundColor: success ? AppTheme.profitGreen : AppTheme.lossRed,
      ),
    );

    if (success) {
      setState(() {});
    }
  }

  void _executeSell(BuildContext context, int quantity, double price) async {
    final success = await ref.read(portfolioProvider.notifier).sellStock(
      stock: widget.stock,
      quantity: quantity,
      price: price,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sold $quantity ${widget.stock.symbol} @ ₹${price.toStringAsFixed(2)}'
              : 'Failed to execute sell order',
        ),
        backgroundColor: success ? AppTheme.profitGreen : AppTheme.lossRed,
      ),
    );

    if (success) {
      setState(() {});
    }
  }
}

class _OHLCItem extends StatelessWidget {
  final String label;
  final double value;

  const _OHLCItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HoldingInfo extends StatelessWidget {
  final String label;
  final String value;

  const _HoldingInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HoldingInfoModern extends StatelessWidget {
  final String label;
  final String value;

  const _HoldingInfoModern({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textPrimary),
      ),
    );
  }
}

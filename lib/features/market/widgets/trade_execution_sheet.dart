import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/domain/models/holding.dart';
import 'package:purple_tomato/core/providers/portfolio_provider.dart';
import 'package:purple_tomato/core/providers/wallet_provider.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';
import 'stock_detail_components.dart';

class TradeExecutionSheet extends ConsumerStatefulWidget {
  final Stock stock;
  final double livePrice;
  final Holding? holding;
  final VoidCallback? onTradeExecuted;

  const TradeExecutionSheet({
    super.key,
    required this.stock,
    required this.livePrice,
    this.holding,
    this.onTradeExecuted,
  });

  @override
  ConsumerState<TradeExecutionSheet> createState() => _TradeExecutionSheetState();
}

class _TradeExecutionSheetState extends ConsumerState<TradeExecutionSheet> {
  bool _isBuyMode = true;
  int _quantity = 1;
  String _orderType = 'Market';
  late TextEditingController _targetPriceController;

  @override
  void initState() {
    super.initState();
    _targetPriceController = TextEditingController(
      text: widget.livePrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holding = widget.holding;
    final livePrice = widget.livePrice;

    final targetPrice = double.tryParse(_targetPriceController.text) ?? livePrice;
    final executionPrice = _orderType == 'Market' ? livePrice : targetPrice;
    final totalPrice = executionPrice * _quantity;

    return Container(
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
                          color: _isBuyMode ? Colors.white : AppTheme.textMuted,
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
                            const Icon(
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
          
          // Quantity Selection
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
                  QuantityButton(
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
                  QuantityButton(
                    icon: Icons.add,
                    onTap: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Order Type Chips
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
          
          if (_orderType != 'Market') ...[
            const SizedBox(height: 20),
            // Target / Trigger Price Input Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderType == 'Limit' ? 'Limit Target Price (₹)' : 'Stop-Loss Trigger Price (₹)',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    filled: true,
                    fillColor: AppTheme.cardElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.accentPurple),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          
          // Price & Total Summary
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
                    Text(_orderType == 'Market' ? 'Market Price' : 'Target Price', style: TextStyle(color: AppTheme.textMuted)),
                    Text(
                      '₹${executionPrice.toStringAsFixed(2)}',
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
                    const Text(
                      'Total Value',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${totalPrice.toStringAsFixed(2)}',
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
                if (_orderType == 'Market') {
                  if (_isBuyMode) {
                    _executeBuy(context, _quantity, livePrice);
                  } else {
                    _validateAndExecuteSell(context, _quantity, livePrice);
                  }
                } else if (_orderType == 'Limit') {
                  if (_isBuyMode) {
                    _executeLimitBuy(context, _quantity, targetPrice);
                  } else {
                    _executeLimitSell(context, _quantity, targetPrice);
                  }
                } else if (_orderType == 'SL') {
                  _executeStopLoss(context, _quantity, targetPrice);
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
                _orderType == 'Market'
                    ? '${_isBuyMode ? 'BUY' : 'SELL'} ${widget.stock.symbol}'
                    : (_orderType == 'Limit'
                        ? 'PLACE LIMIT ${_isBuyMode ? 'BUY' : 'SELL'}'
                        : 'SET STOP-LOSS'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeChip(String label) {
    final isSelected = _orderType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _orderType = label;
          if (label == 'SL') {
            _targetPriceController.text = (widget.livePrice * 0.95).toStringAsFixed(2);
          } else {
            _targetPriceController.text = widget.livePrice.toStringAsFixed(2);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple : AppTheme.cardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentPurple : AppTheme.borderDefault,
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

  void _validateAndExecuteSell(BuildContext context, int quantity, double price) {
    final holding = widget.holding;
    if (holding == null || holding.quantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t own this stock. Buy first to sell.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    if (holding.quantity < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient shares. You only have ${holding.quantity} shares.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }
    _executeSell(context, quantity, price);
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

    if (context.mounted) {
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
    }

    if (success && widget.onTradeExecuted != null) {
      widget.onTradeExecuted!();
    }
  }

  void _executeSell(BuildContext context, int quantity, double price) async {
    final success = await ref.read(portfolioProvider.notifier).sellStock(
          stock: widget.stock,
          quantity: quantity,
          price: price,
        );

    if (context.mounted) {
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
    }

    if (success && widget.onTradeExecuted != null) {
      widget.onTradeExecuted!();
    }
  }

  void _executeLimitBuy(BuildContext context, int quantity, double targetPrice) async {
    final success = await ref.read(portfolioProvider.notifier).placeLimitBuy(
          stock: widget.stock,
          quantity: quantity,
          targetPrice: targetPrice,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Limit Buy placed for $quantity ${widget.stock.symbol} @ ₹${targetPrice.toStringAsFixed(2)}'
                : 'Failed to place limit buy order (insufficient funds)',
          ),
          backgroundColor: success ? AppTheme.profitGreen : AppTheme.lossRed,
        ),
      );
    }

    if (success && widget.onTradeExecuted != null) {
      widget.onTradeExecuted!();
    }
  }

  void _executeLimitSell(BuildContext context, int quantity, double targetPrice) async {
    final success = await ref.read(portfolioProvider.notifier).placeLimitSell(
          stock: widget.stock,
          quantity: quantity,
          targetPrice: targetPrice,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Limit Sell placed for $quantity ${widget.stock.symbol} @ ₹${targetPrice.toStringAsFixed(2)}'
                : 'Failed to place limit sell order',
          ),
          backgroundColor: success ? AppTheme.profitGreen : AppTheme.lossRed,
        ),
      );
    }

    if (success && widget.onTradeExecuted != null) {
      widget.onTradeExecuted!();
    }
  }

  void _executeStopLoss(BuildContext context, int quantity, double triggerPrice) async {
    final success = await ref.read(portfolioProvider.notifier).placeStopLoss(
          stock: widget.stock,
          quantity: quantity,
          triggerPrice: triggerPrice,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Stop-Loss trigger set for $quantity ${widget.stock.symbol} @ ₹${triggerPrice.toStringAsFixed(2)}'
                : 'Failed to set stop-loss order',
          ),
          backgroundColor: success ? AppTheme.warningOrange : AppTheme.lossRed,
        ),
      );
    }

    if (success && widget.onTradeExecuted != null) {
      widget.onTradeExecuted!();
    }
  }
}

import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

/// Widget to display P&L with color coding
class PnlDisplay extends StatelessWidget {
  final double pnlAmount;
  final double pnlPercent;
  final bool showLabel;
  final bool compact;

  const PnlDisplay({
    super.key,
    required this.pnlAmount,
    required this.pnlPercent,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = pnlAmount >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
    final sign = isPositive ? '+' : '';

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sign₹${pnlAmount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$sign${pnlPercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showLabel)
          const Text(
            'P&L',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$sign₹${_formatAmount(pnlAmount.abs())}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$sign${pnlPercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}

/// Large P&L card for portfolio summary
class PnlCard extends StatelessWidget {
  final double totalPnl;
  final double pnlPercent;
  final double investedValue;
  final double currentValue;

  const PnlCard({
    super.key,
    required this.totalPnl,
    required this.pnlPercent,
    required this.investedValue,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = totalPnl >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Total P&L
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$sign₹${_formatLargeAmount(totalPnl.abs())}',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$sign${pnlPercent.toStringAsFixed(2)}% ${isPositive ? 'Profit' : 'Loss'}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          
          // Invested vs Current - Clean Row Design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValueColumn('Invested', investedValue, CrossAxisAlignment.start),
                _buildValueColumn('Current', currentValue, CrossAxisAlignment.end),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(String label, double value, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${_formatLargeAmount(value)}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatLargeAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}

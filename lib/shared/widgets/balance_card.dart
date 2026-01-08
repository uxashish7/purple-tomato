import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

/// Balance card widget for displaying wallet info
class BalanceCard extends StatelessWidget {
  final double balance;
  final double? initialBalance;
  final VoidCallback? onReset;
  final bool showReset;

  const BalanceCard({
    super.key,
    required this.balance,
    this.initialBalance,
    this.onReset,
    this.showReset = true,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = initialBalance != null ? balance - initialBalance! : 0.0;
    final pnlPercent = initialBalance != null && initialBalance! > 0
        ? (pnl / initialBalance!) * 100
        : 0.0;
    final isPositive = pnl >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A24),
            Color(0xFF12121A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.1),
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
              const Text(
                'Virtual Cash',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'VIRTUAL CASH',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                _formatBalance(balance),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          
          // P&L from initial
          if (initialBalance != null && initialBalance != balance) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isPositive ? AppTheme.profitGreen : AppTheme.lossRed,
                  size: 20,
                ),
                Text(
                  '${isPositive ? '+' : ''}₹${_formatBalance(pnl.abs())} (${pnlPercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isPositive ? AppTheme.profitGreen : AppTheme.lossRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  ' from start',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          
          // Reset button
          if (showReset && onReset != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Portfolio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warningOrange,
                  side: BorderSide(
                    color: AppTheme.warningOrange.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBalance(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Format with commas for Indian style
      final parts = amount.toStringAsFixed(2).split('.');
      final whole = parts[0];
      final decimal = parts[1];
      
      if (whole.length <= 3) {
        return '$whole.$decimal';
      }
      
      final last3 = whole.substring(whole.length - 3);
      final rest = whole.substring(0, whole.length - 3);
      
      String formatted = '';
      for (int i = rest.length - 1, count = 0; i >= 0; i--, count++) {
        if (count > 0 && count % 2 == 0) {
          formatted = ',$formatted';
        }
        formatted = rest[i] + formatted;
      }
      
      return '$formatted,$last3.$decimal';
    }
  }
}

/// Compact balance display for app bar
class BalanceChip extends StatelessWidget {
  final double balance;

  const BalanceChip({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: AppTheme.primaryGreen,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '₹${_formatCompact(balance)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}

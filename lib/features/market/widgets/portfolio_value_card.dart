import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/theme/app_theme.dart';

class PortfolioValueCard extends StatefulWidget {
  final double totalValue;
  final double overallPnL;
  final double overallPnLPercent;
  final double availableCash;
  final double investedValue;
  final double currentValue;

  const PortfolioValueCard({
    required this.totalValue,
    required this.overallPnL,
    required this.overallPnLPercent,
    required this.availableCash,
    required this.investedValue,
    required this.currentValue,
  });

  @override
  State<PortfolioValueCard> createState() => _PortfolioValueCardState();
}

class _PortfolioValueCardState extends State<PortfolioValueCard> {
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

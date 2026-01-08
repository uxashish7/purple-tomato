import 'package:flutter/material.dart';
import '../../core/models/stock.dart';
import '../../shared/theme/app_theme.dart';
import 'price_change_indicator.dart';

/// Reusable stock tile widget for lists
class StockTile extends StatelessWidget {
  final Stock stock;
  final double? price;
  final double? change;
  final double? changePercent;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showPrice;

  const StockTile({
    super.key,
    required this.stock,
    this.price,
    this.change,
    this.changePercent,
    this.onTap,
    this.trailing,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Stock icon/avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stock.symbol.substring(0, stock.symbol.length > 2 ? 2 : stock.symbol.length),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Stock info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.name,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Price and change
              if (showPrice && price != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (changePercent != null)
                      PriceChangeChip(changePercent: changePercent!),
                  ],
                ),
              
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact stock chip for horizontal lists
class StockChip extends StatelessWidget {
  final Stock stock;
  final double? price;
  final double? changePercent;
  final VoidCallback? onTap;

  const StockChip({
    super.key,
    required this.stock,
    this.price,
    this.changePercent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (changePercent ?? 0) >= 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPositive 
                ? AppTheme.profitGreen.withOpacity(0.3)
                : AppTheme.lossRed.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stock.symbol,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            if (price != null)
              Text(
                '₹${price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            if (changePercent != null)
              Text(
                '${changePercent! >= 0 ? '+' : ''}${changePercent!.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? AppTheme.profitGreen : AppTheme.lossRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

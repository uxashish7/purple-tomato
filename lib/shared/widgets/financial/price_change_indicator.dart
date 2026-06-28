import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

/// Widget to display price change with arrow and color coding
class PriceChangeIndicator extends StatelessWidget {
  final double change;
  final double changePercent;
  final bool showIcon;
  final double fontSize;

  const PriceChangeIndicator({
    super.key,
    required this.change,
    required this.changePercent,
    this.showIcon = true,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
    final icon = isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final sign = isPositive ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Icon(
            icon,
            color: color,
            size: fontSize + 8,
          ),
        Text(
          '$sign${change.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
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
            '$sign${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version for lists
class PriceChangeChip extends StatelessWidget {
  final double changePercent;
  
  const PriceChangeChip({
    super.key,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final color = isPositive ? AppTheme.profitGreen : AppTheme.lossRed;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$sign${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

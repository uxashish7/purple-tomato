import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';
import 'package:purple_tomato/domain/models/holding.dart';
import 'dart:math';

class PortfolioAllocationSection extends StatelessWidget {
  final List holdings;
  final Map<String, double> livePrices;
  final double totalValue;

  const PortfolioAllocationSection({
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

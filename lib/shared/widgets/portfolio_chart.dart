import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

/// Portfolio performance chart with time period selector - Modern Indian app style
class PortfolioChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double? startValue;
  final double? currentValue;
  final bool hasHoldings;

  const PortfolioChart({
    super.key,
    required this.values,
    required this.labels,
    this.startValue,
    this.currentValue,
    this.hasHoldings = true,
  });

  @override
  State<PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<PortfolioChart> {
  String _selectedPeriod = '1W';
  final List<String> _periods = ['1D', '1W', '1M', '3M', '1Y', 'All'];
  
  late List<double> _currentValues;

  @override
  void initState() {
    super.initState();
    _currentValues = widget.values;
  }

  @override
  void didUpdateWidget(PortfolioChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _currentValues = widget.values;
    }
  }

  /// Generate simulated data based on selected period and current/start values
  void _updateChartData(String period) {
    if (widget.currentValue == null || widget.startValue == null) return;
    
    final current = widget.currentValue!;
    final initial = widget.startValue!; // This is account start value
    
    // Determine simulated start value for this specific period
    double periodStart;
    int points;
    double volatility;

    switch (period) {
      case '1D':
        // Day: Small variance from current
        periodStart = current * (1 + (DateTime.now().second % 2 == 0 ? -0.01 : 0.01)); 
        points = 24; // Hours
        volatility = 0.005;
        break;
      case '1W':
        // Week: 7 days
        periodStart = current * 0.98; // Simulated 2% growth
        points = 7;
        volatility = 0.02;
        break;
      case '1M':
        // Month: 30 days
        periodStart = current * 0.95; // Simulated 5% growth
        points = 30;
        volatility = 0.03;
        break;
      case '3M':
        periodStart = current * 0.90;
        points = 45;
        volatility = 0.04;
        break;
      case '1Y':
        periodStart = current * 0.85;
        points = 60;
        volatility = 0.06;
        break;
      case 'All':
      default:
        periodStart = initial;
        points = 50;
        volatility = 0.08;
        break;
    }

    // Check if we already have the correct values (for 'All' or initial '1W' passed from parent)
    // Actually, providing fresh random data makes it feel responsive.
    
    _currentValues = _generateSimulatedPoints(periodStart, current, points, volatility);
    _selectedPeriod = period;
    setState(() {});
  }

  List<double> _generateSimulatedPoints(double start, double end, int count, double volatility) {
    final List<double> points = [];
    final totalDiff = end - start;
    
    for (int i = 0; i < count; i++) {
        // Progress 0.0 to 1.0 (excluding last point which is strictly 'end')
        double progress = i / (count - 1);
        
        // Linear path
        double linearValue = start + (totalDiff * progress);
        
        // Add random noise, but dampen it at start and end
        double noiseFactor = 1.0 - (2 * (progress - 0.5)).abs(); // Peaked at center
        double noise = (linearValue * volatility * noiseFactor) * ((i % 3 == 0 ? 1 : -1) * 0.5);
        
        points.add(linearValue + noise);
    }
    
    // Ensure exact endpoints logic (though loop handles it, let's look roughly correct)
    // Force last point to be exactly 'end'
    if (points.isNotEmpty) points.last = end;
    
    return points;
  }

  String _formatCompact(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentValues.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use simulated start for the chart visual (first point), unless it's 'All' where we use true initial.
    // For specific periods, the 'Start' label might refer to the period start.
    final displayStartVal = _currentValues.first;
    final displayCurrentVal = _currentValues.last;
    
    final pnl = displayCurrentVal - displayStartVal;
    final pnlPercent = displayStartVal > 0 ? (pnl / displayStartVal) * 100 : 0;
    
    // If no holdings, show neutral state (0% change)
    final bool showNeutral = !widget.hasHoldings;
    final isPositive = showNeutral ? true : pnl >= 0;
    final lineColor = showNeutral ? AppTheme.textSecondary : (isPositive ? AppTheme.profitGreen : AppTheme.lossRed);
    final displayPnlPercent = showNeutral ? 0.0 : pnlPercent;
    final displayPnl = showNeutral ? 0.0 : pnl;

    final minValue = _currentValues.reduce((a, b) => a < b ? a : b);
    final maxValue = _currentValues.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    // Prevent division by zero if flat line
    final safeRange = range == 0 ? 1.0 : range;
    final padding = safeRange * 0.15;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDefault.withOpacity(0.5), // Slightly more opaque for contrast
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and current value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Performance',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCompact(displayCurrentVal),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // P&L Badge in Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lineColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showNeutral ? Icons.remove : (isPositive ? Icons.trending_up : Icons.trending_down),
                      color: lineColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      showNeutral ? '0.00%' : '${isPositive ? '+' : ''}${displayPnlPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: lineColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // P&L amount text
          Text(
            showNeutral 
              ? 'No investments yet'
              : '${isPositive ? '+' : ''}${_formatCompact(displayPnl.abs())} ${isPositive ? 'profit' : 'loss'}',
            style: TextStyle(
              color: lineColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeRange / 3,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.03),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_currentValues.length - 1).toDouble(),
                minY: minValue - padding,
                maxY: maxValue + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: _currentValues
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.2),
                          lineColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF1E1E2C),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          _formatCompact(spot.y),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Time period selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: _periods.map((period) {
                final isSelected = period == _selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateChartData(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? lineColor.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected ? lineColor : AppTheme.textTertiary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Labels "Start" vs "Current" or "Period Low" vs "Period High"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Low: ${_formatCompact(minValue)}',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
              ),
              Text(
                'High: ${_formatCompact(maxValue)}',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mini sparkline chart for quick visualization
class SparklineChart extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final double height;
  final double width;

  const SparklineChart({
    super.key,
    required this.values,
    this.color,
    this.height = 40,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.length < 2) {
      return SizedBox(height: height, width: width);
    }

    final isPositive = values.last >= values.first;
    final lineColor = color ?? (isPositive ? AppTheme.profitGreen : AppTheme.lossRed);
    
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: minValue,
          maxY: maxValue,
          lineBarsData: [
            LineChartBarData(
              spots: values
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

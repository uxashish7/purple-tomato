import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../../core/services/yahoo_finance_service.dart';

/// TradingView-style Chart Widget using fl_chart
/// Supports both Line and Candlestick views with proper X-axis scaling
class StockCandlestickChart extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  
  const StockCandlestickChart({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  @override
  State<StockCandlestickChart> createState() => _StockCandlestickChartState();
}

class _StockCandlestickChartState extends State<StockCandlestickChart> {
  final YahooFinanceService _yahooService = YahooFinanceService();
  List<OHLCData> _ohlcData = [];
  bool _isLoading = true;
  bool _showCandlestick = true; // Toggle between line and candlestick
  String _selectedPeriod = '1M';
  String? _error;
  
  // Zoom state
  double _zoomLevel = 1.0;  // 1.0 = full view, 4.0 = max zoom
  
  final List<Map<String, String>> _periods = [
    {'label': '1D', 'range': '1d', 'interval': '5m'},
    {'label': '1W', 'range': '5d', 'interval': '15m'},
    {'label': '1M', 'range': '1mo', 'interval': '1d'},
    {'label': '3M', 'range': '3mo', 'interval': '1d'},
    {'label': '1Y', 'range': '1y', 'interval': '1wk'},
    {'label': 'All', 'range': '5y', 'interval': '1mo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOHLCData();
  }

  Future<void> _loadOHLCData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final periodConfig = _periods.firstWhere(
      (p) => p['label'] == _selectedPeriod,
      orElse: () => _periods[2],
    );
    
    try {
      final ohlcData = await _yahooService.getHistoricalOHLC(
        widget.symbol,
        period: periodConfig['range']!,
        interval: periodConfig['interval']!,
      );
      
      // Sort by date ascending for proper chart display
      ohlcData.sort((a, b) => a.date.compareTo(b.date));
      
      setState(() {
        _ohlcData = ohlcData;
        _isLoading = false;
      });
      
      print('Chart: Loaded ${ohlcData.length} candles for ${widget.symbol}');
    } catch (e) {
      print('Chart error: $e');
      setState(() {
        _error = 'Failed to load chart data';
        _isLoading = false;
      });
    }
  }

  /// Smart date formatting based on selected period
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    switch (_selectedPeriod) {
      case '1D':
        // Show time for intraday: 2:30 PM
        final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final amPm = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:${date.minute.toString().padLeft(2, '0')} $amPm';
      case '1W':
        // Show day name: Mon 6
        return '${days[date.weekday - 1]} ${date.day}';
      case '1M':
        // Show month and day: Jan 15
        return '${months[date.month - 1]} ${date.day}';
      default:
        // 3M, 1Y, All: Show year and month: 2026 Jan
        return '${date.year} ${months[date.month - 1]}';
    }
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    _loadOHLCData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardDark,
            AppTheme.backgroundDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.candlestick_chart,
                      color: AppTheme.accentPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Price Chart',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Line / Candlestick Toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToggleButton(
                        icon: Icons.show_chart,
                        isSelected: !_showCandlestick,
                        onTap: () => setState(() => _showCandlestick = false),
                      ),
                      _ToggleButton(
                        icon: Icons.candlestick_chart,
                        isSelected: _showCandlestick,
                        onTap: () => setState(() => _showCandlestick = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Zoom controls
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ZoomButton(
                        icon: Icons.remove,
                        onTap: _zoomLevel > 1.0
                            ? () => setState(() => _zoomLevel = (_zoomLevel - 0.5).clamp(1.0, 4.0))
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${_zoomLevel.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      _ZoomButton(
                        icon: Icons.add,
                        onTap: _zoomLevel < 4.0
                            ? () => setState(() => _zoomLevel = (_zoomLevel + 0.5).clamp(1.0, 4.0))
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chart Area
          SizedBox(
            height: 250,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPurple,
                      strokeWidth: 2,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : _ohlcData.isEmpty
                        ? Center(
                            child: Text(
                              'No chart data available',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _showCandlestick 
                                ? _buildCandlestickChart()
                                : _buildLineChart(),
                          ),
          ),
          
          // Time Period Selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: _periods.map((period) {
                  final isSelected = period['label'] == _selectedPeriod;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onPeriodChanged(period['label']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentPurple.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppTheme.accentPurple.withOpacity(0.5))
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            period['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.accentPurple
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Line Chart using fl_chart
  Widget _buildLineChart() {
    if (_ohlcData.isEmpty) return const SizedBox();
    
    // Get visible data based on zoom level (zoom shows last N items)
    final visibleCount = (_ohlcData.length / _zoomLevel).round().clamp(5, _ohlcData.length);
    final startIndex = _ohlcData.length - visibleCount;
    final visibleData = _ohlcData.sublist(startIndex);
    
    final spots = <FlSpot>[];
    for (int i = 0; i < visibleData.length; i++) {
      spots.add(FlSpot(i.toDouble(), visibleData[i].close));
    }
    
    final minY = visibleData.map((d) => d.low).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = visibleData.map((d) => d.high).reduce((a, b) => a > b ? a : b) * 1.005;
    
    // Determine if overall trend is up or down
    final isUp = visibleData.last.close >= visibleData.first.open;
    final chartColor = isUp ? AppTheme.profitGreen : AppTheme.lossRed;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (_ohlcData.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _ohlcData.length) return const SizedBox();
                final date = _ohlcData[index].date;
                return Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: chartColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  chartColor.withOpacity(0.3),
                  chartColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.cardDark,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                if (index < 0 || index >= _ohlcData.length) return null;
                final data = _ohlcData[index];
                return LineTooltipItem(
                  '₹${data.close.toStringAsFixed(2)}\n${data.date.day}/${data.date.month}',
                  TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Build Candlestick Chart using fl_chart BarChart
  Widget _buildCandlestickChart() {
    if (_ohlcData.isEmpty) return const SizedBox();
    
    // Get visible data based on zoom level (zoom shows last N items)
    final visibleCount = (_ohlcData.length / _zoomLevel).round().clamp(5, _ohlcData.length);
    final startIndex = _ohlcData.length - visibleCount;
    final visibleData = _ohlcData.sublist(startIndex);
    
    final minY = visibleData.map((d) => d.low).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = visibleData.map((d) => d.high).reduce((a, b) => a > b ? a : b) * 1.005;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.cardDark,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= _ohlcData.length) return null;
              final data = _ohlcData[groupIndex];
              return BarTooltipItem(
                'O: ₹${data.open.toStringAsFixed(2)}\n'
                'H: ₹${data.high.toStringAsFixed(2)}\n'
                'L: ₹${data.low.toStringAsFixed(2)}\n'
                'C: ₹${data.close.toStringAsFixed(2)}',
                TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // Show fewer labels to avoid crowding
                if (index < 0 || index >= _ohlcData.length) return const SizedBox();
                if (index % ((_ohlcData.length / 4).ceil()) != 0) return const SizedBox();
                final date = _ohlcData[index].date;
                return Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildCandlestickBars(visibleData, minY, maxY),
      ),
    );
  }

  List<BarChartGroupData> _buildCandlestickBars(List<OHLCData> data, double minY, double maxY) {
    final List<BarChartGroupData> bars = [];
    
    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final isUp = candle.close >= candle.open;
      final color = isUp ? AppTheme.profitGreen : AppTheme.lossRed;
      
      // Candlestick is drawn as a bar from low to high with body from open to close
      final bodyTop = isUp ? candle.close : candle.open;
      final bodyBottom = isUp ? candle.open : candle.close;
      
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Wick (thin line from low to high)
            BarChartRodData(
              toY: candle.high,
              fromY: candle.low,
              color: color.withOpacity(0.6),
              width: 1,
              borderRadius: BorderRadius.zero,
            ),
            // Body (thick bar from open to close)
            BarChartRodData(
              toY: bodyTop,
              fromY: bodyBottom,
              color: color,
              width: data.length > 50 ? 3 : (data.length > 20 ? 5 : 8),
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    
    return bars;
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? AppTheme.accentPurple : AppTheme.textMuted,
        ),
      ),
    );
  }
}

/// Zoom button widget for +/- controls
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.textPrimary : AppTheme.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }
}

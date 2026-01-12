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
    
    final spots = <FlSpot>[];
    for (int i = 0; i < _ohlcData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _ohlcData[i].close));
    }
    
    final minY = _ohlcData.map((d) => d.low).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = _ohlcData.map((d) => d.high).reduce((a, b) => a > b ? a : b) * 1.005;
    
    // Determine if overall trend is up or down
    final isUp = _ohlcData.last.close >= _ohlcData.first.open;
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
                  '${date.day}/${date.month}',
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
            getTooltipColor: (_) => AppTheme.cardDark,
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
    
    final minY = _ohlcData.map((d) => d.low).reduce((a, b) => a < b ? a : b) * 0.995;
    final maxY = _ohlcData.map((d) => d.high).reduce((a, b) => a > b ? a : b) * 1.005;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardDark,
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
                  '${date.day}/${date.month}',
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
        barGroups: _buildCandlestickBars(minY, maxY),
      ),
    );
  }

  List<BarChartGroupData> _buildCandlestickBars(double minY, double maxY) {
    final List<BarChartGroupData> bars = [];
    
    for (int i = 0; i < _ohlcData.length; i++) {
      final data = _ohlcData[i];
      final isUp = data.close >= data.open;
      final color = isUp ? AppTheme.profitGreen : AppTheme.lossRed;
      
      // Candlestick is drawn as a bar from low to high with body from open to close
      final bodyTop = isUp ? data.close : data.open;
      final bodyBottom = isUp ? data.open : data.close;
      
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // Wick (thin line from low to high)
            BarChartRodData(
              toY: data.high,
              fromY: data.low,
              color: color.withOpacity(0.6),
              width: 1,
              borderRadius: BorderRadius.zero,
            ),
            // Body (thick bar from open to close)
            BarChartRodData(
              toY: bodyTop,
              fromY: bodyBottom,
              color: color,
              width: _ohlcData.length > 50 ? 3 : (_ohlcData.length > 20 ? 5 : 8),
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

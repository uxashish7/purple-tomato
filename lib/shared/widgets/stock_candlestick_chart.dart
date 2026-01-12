import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../theme/app_theme.dart';
import '../../core/services/yahoo_finance_service.dart';

/// TradingView-style Candlestick Chart Widget
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
  List<Candle> _candles = [];
  bool _isLoading = true;
  bool _showCandlestick = true; // Toggle between line and candlestick
  String _selectedPeriod = '1M';
  
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
    setState(() => _isLoading = true);
    
    final periodConfig = _periods.firstWhere(
      (p) => p['label'] == _selectedPeriod,
      orElse: () => _periods[2],
    );
    
    final ohlcData = await _yahooService.getHistoricalOHLC(
      widget.symbol,
      period: periodConfig['range']!,
      interval: periodConfig['interval']!,
    );
    
    // Convert to Candle format for the candlesticks package
    final candles = ohlcData.map((data) => Candle(
      date: data.date,
      open: data.open,
      high: data.high,
      low: data.low,
      close: data.close,
      volume: data.volume,
    )).toList();
    
    // Candlesticks package expects newest first
    candles.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _candles = candles;
      _isLoading = false;
    });
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
                : _candles.isEmpty
                    ? Center(
                        child: Text(
                          'No chart data available',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Candlesticks(
                          candles: _candles,
                          onLoadMoreCandles: () async {},
                          actions: [],
                        ),
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

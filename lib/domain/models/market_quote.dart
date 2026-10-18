class MarketQuote {
  final String instrumentKey;
  final double lastPrice;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final DateTime? timestamp;

  MarketQuote({
    required this.instrumentKey,
    required this.lastPrice,
    this.change = 0,
    this.changePercent = 0,
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
    this.volume = 0,
    this.timestamp,
  });

  bool get isPositive => change >= 0;
  bool get isNegative => change < 0;

  factory MarketQuote.fromUpstoxJson(String instrumentKey, Map<String, dynamic> json) {
    final ohlc = json['ohlc'] ?? {};
    final ltp = (json['last_price'] ?? json['ltp'] ?? 0).toDouble();
    final cp = (json['cp'] ?? ohlc['close'] ?? 0).toDouble();
    double netChange = (json['net_change'] ?? json['change'] ?? 0).toDouble();
    if (netChange == 0 && cp > 0 && ltp > 0) {
      netChange = ltp - cp;
    }
    double pChange = (json['percentage_change'] ?? json['pChange'] ?? 0).toDouble();
    if (pChange == 0 && cp > 0 && netChange != 0) {
      pChange = (netChange / cp) * 100;
    }

    return MarketQuote(
      instrumentKey: json['instrument_token']?.toString() ?? instrumentKey,
      lastPrice: ltp,
      change: netChange,
      changePercent: pChange,
      open: (ohlc['open'] ?? 0).toDouble(),
      high: (ohlc['high'] ?? 0).toDouble(),
      low: (ohlc['low'] ?? 0).toDouble(),
      close: cp > 0 ? cp : (ohlc['close'] ?? 0).toDouble(),
      volume: json['volume'] ?? json['total_buy_quantity'] ?? 0,
      timestamp: json['last_trade_time'] != null
          ? DateTime.tryParse(json['last_trade_time'])
          : null,
    );
  }

  factory MarketQuote.mock({
    required String instrumentKey,
    required double lastPrice,
    double change = 0,
    double changePercent = 0,
  }) {
    return MarketQuote(
      instrumentKey: instrumentKey,
      lastPrice: lastPrice,
      change: change,
      changePercent: changePercent,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() => '$instrumentKey: ₹$lastPrice ($changePercent%)';
}

class IndexQuote {
  final String name;
  final String instrumentKey;
  final double value;
  final double change;
  final double changePercent;

  IndexQuote({
    required this.name,
    required this.instrumentKey,
    required this.value,
    this.change = 0,
    this.changePercent = 0,
  });

  bool get isPositive => change >= 0;

  factory IndexQuote.fromUpstoxJson(String name, String instrumentKey, Map<String, dynamic> json) {
    final ltp = (json['last_price'] ?? json['ltp'] ?? 0).toDouble();
    final cp = (json['cp'] ?? 0).toDouble();
    double netChange = (json['net_change'] ?? json['change'] ?? 0).toDouble();
    if (netChange == 0 && cp > 0 && ltp > 0) {
      netChange = ltp - cp;
    }
    double pChange = (json['percentage_change'] ?? json['pChange'] ?? 0).toDouble();
    if (pChange == 0 && cp > 0 && netChange != 0) {
      pChange = (netChange / cp) * 100;
    }

    return IndexQuote(
      name: name,
      instrumentKey: instrumentKey,
      value: ltp,
      change: netChange,
      changePercent: pChange,
    );
  }

  factory IndexQuote.mock({
    required String name,
    required String instrumentKey,
    required double value,
    double change = 0,
    double changePercent = 0,
  }) {
    return IndexQuote(
      name: name,
      instrumentKey: instrumentKey,
      value: value,
      change: change,
      changePercent: changePercent,
    );
  }
}

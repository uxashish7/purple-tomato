/// Portfolio snapshot model for storing historical portfolio values
class PortfolioSnapshot {
  final String id;
  final String deviceId;
  final DateTime timestamp;
  final double totalValue;
  final double cashBalance;
  final double investedAmount;
  final double holdingsValue;

  PortfolioSnapshot({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.totalValue,
    required this.cashBalance,
    required this.investedAmount,
    required this.holdingsValue,
  });

  /// Create from Supabase JSON response
  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      totalValue: (json['total_value'] as num).toDouble(),
      cashBalance: (json['cash_balance'] as num).toDouble(),
      investedAmount: (json['invested_amount'] as num).toDouble(),
      holdingsValue: (json['holdings_value'] as num).toDouble(),
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'total_value': totalValue,
      'cash_balance': cashBalance,
      'invested_amount': investedAmount,
      'holdings_value': holdingsValue,
    };
  }
}

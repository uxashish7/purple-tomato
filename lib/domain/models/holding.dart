import 'package:hive/hive.dart';
import 'stock.dart';

part 'holding.g.dart';

@HiveType(typeId: 1)
class Holding {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Stock stock;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  double avgBuyPrice;

  @HiveField(4)
  final DateTime purchaseDate;

  Holding({
    required this.id,
    required this.stock,
    required this.quantity,
    required this.avgBuyPrice,
    required this.purchaseDate,
  });

  /// Total invested value
  double get investedValue => avgBuyPrice * quantity;

  /// Calculate current value based on live price
  double currentValue(double livePrice) => livePrice * quantity;

  /// Calculate P&L amount
  double pnlAmount(double livePrice) => currentValue(livePrice) - investedValue;

  /// Calculate P&L percentage
  double pnlPercent(double livePrice) {
    if (investedValue == 0) return 0;
    return (pnlAmount(livePrice) / investedValue) * 100;
  }

  /// Update holding when adding more shares (average out)
  void addShares(int newQuantity, double newPrice) {
    final totalInvested = investedValue + (newPrice * newQuantity);
    final totalQuantity = quantity + newQuantity;
    avgBuyPrice = totalInvested / totalQuantity;
    quantity = totalQuantity;
  }

  /// Reduce shares (for selling)
  void reduceShares(int sellQuantity) {
    if (sellQuantity > quantity) {
      throw Exception('Cannot sell more shares than owned');
    }
    quantity -= sellQuantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock': stock.toJson(),
      'quantity': quantity,
      'avgBuyPrice': avgBuyPrice,
      'purchaseDate': purchaseDate.toIso8601String(),
    };
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'],
      stock: Stock.fromJson(json['stock']),
      quantity: json['quantity'],
      avgBuyPrice: json['avgBuyPrice'].toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
    );
  }

  @override
  String toString() => '${stock.symbol}: $quantity @ ₹$avgBuyPrice';
}

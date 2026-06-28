import 'package:hive/hive.dart';
import 'stock.dart';

part 'order.g.dart';

enum OrderType { buy, sell }

@HiveType(typeId: 2)
class Order {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Stock stock;

  @HiveField(2)
  final int orderType; // 0 = buy, 1 = sell (stored as int for Hive)

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final double totalValue;

  Order({
    required this.id,
    required this.stock,
    required this.orderType,
    required this.quantity,
    required this.price,
    required this.timestamp,
    required this.totalValue,
  });

  OrderType get type => orderType == 0 ? OrderType.buy : OrderType.sell;

  bool get isBuy => orderType == 0;
  bool get isSell => orderType == 1;

  factory Order.buy({
    required String id,
    required Stock stock,
    required int quantity,
    required double price,
  }) {
    return Order(
      id: id,
      stock: stock,
      orderType: 0,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
      totalValue: price * quantity,
    );
  }

  factory Order.sell({
    required String id,
    required Stock stock,
    required int quantity,
    required double price,
  }) {
    return Order(
      id: id,
      stock: stock,
      orderType: 1,
      quantity: quantity,
      price: price,
      timestamp: DateTime.now(),
      totalValue: price * quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock': stock.toJson(),
      'orderType': orderType,
      'quantity': quantity,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
      'totalValue': totalValue,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      stock: Stock.fromJson(json['stock']),
      orderType: json['orderType'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      totalValue: json['totalValue'].toDouble(),
    );
  }

  @override
  String toString() =>
      '${isBuy ? "BUY" : "SELL"} ${stock.symbol} x$quantity @ ₹$price';
}

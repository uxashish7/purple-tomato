import 'package:hive/hive.dart';
import 'stock.dart';

part 'order.g.dart';

enum OrderType { buy, sell }
enum ExecutionType { market, limit, stopLoss }
enum OrderStatus { executed, pending, cancelled }

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

  @HiveField(7)
  final int executionTypeIndex; // 0 = market, 1 = limit, 2 = stopLoss

  @HiveField(8)
  final int statusIndex; // 0 = executed, 1 = pending, 2 = cancelled

  @HiveField(9)
  final double? targetPrice;

  @HiveField(10)
  final double? triggerPrice;

  Order({
    required this.id,
    required this.stock,
    required this.orderType,
    required this.quantity,
    required this.price,
    required this.timestamp,
    required this.totalValue,
    this.executionTypeIndex = 0,
    this.statusIndex = 0,
    this.targetPrice,
    this.triggerPrice,
  });

  OrderType get type => orderType == 0 ? OrderType.buy : OrderType.sell;
  ExecutionType get executionType => ExecutionType.values[executionTypeIndex.clamp(0, 2)];
  OrderStatus get status => OrderStatus.values[statusIndex.clamp(0, 2)];

  bool get isBuy => orderType == 0;
  bool get isSell => orderType == 1;
  bool get isPending => status == OrderStatus.pending;
  bool get isExecuted => status == OrderStatus.executed;
  bool get isLimit => executionType == ExecutionType.limit;
  bool get isStopLoss => executionType == ExecutionType.stopLoss;

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
      executionTypeIndex: 0,
      statusIndex: 0,
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
      executionTypeIndex: 0,
      statusIndex: 0,
    );
  }

  factory Order.limitBuy({
    required String id,
    required Stock stock,
    required int quantity,
    required double targetPrice,
  }) {
    return Order(
      id: id,
      stock: stock,
      orderType: 0,
      quantity: quantity,
      price: targetPrice,
      timestamp: DateTime.now(),
      totalValue: targetPrice * quantity,
      executionTypeIndex: 1,
      statusIndex: 1,
      targetPrice: targetPrice,
    );
  }

  factory Order.limitSell({
    required String id,
    required Stock stock,
    required int quantity,
    required double targetPrice,
  }) {
    return Order(
      id: id,
      stock: stock,
      orderType: 1,
      quantity: quantity,
      price: targetPrice,
      timestamp: DateTime.now(),
      totalValue: targetPrice * quantity,
      executionTypeIndex: 1,
      statusIndex: 1,
      targetPrice: targetPrice,
    );
  }

  factory Order.stopLoss({
    required String id,
    required Stock stock,
    required int quantity,
    required double triggerPrice,
  }) {
    return Order(
      id: id,
      stock: stock,
      orderType: 1,
      quantity: quantity,
      price: triggerPrice,
      timestamp: DateTime.now(),
      totalValue: triggerPrice * quantity,
      executionTypeIndex: 2,
      statusIndex: 1,
      triggerPrice: triggerPrice,
    );
  }

  Order copyWith({
    int? statusIndex,
    double? price,
  }) {
    final updatedPrice = price ?? this.price;
    return Order(
      id: id,
      stock: stock,
      orderType: orderType,
      quantity: quantity,
      price: updatedPrice,
      timestamp: timestamp,
      totalValue: updatedPrice * quantity,
      executionTypeIndex: executionTypeIndex,
      statusIndex: statusIndex ?? this.statusIndex,
      targetPrice: targetPrice,
      triggerPrice: triggerPrice,
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
      'executionTypeIndex': executionTypeIndex,
      'statusIndex': statusIndex,
      'targetPrice': targetPrice,
      'triggerPrice': triggerPrice,
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
      executionTypeIndex: json['executionTypeIndex'] ?? 0,
      statusIndex: json['statusIndex'] ?? 0,
      targetPrice: json['targetPrice']?.toDouble(),
      triggerPrice: json['triggerPrice']?.toDouble(),
    );
  }

  @override
  String toString() {
    final mode = isLimit ? "LIMIT" : (isStopLoss ? "STOP-LOSS" : "MARKET");
    final side = isBuy ? "BUY" : "SELL";
    final stateStr = isPending ? "[PENDING]" : "[EXECUTED]";
    return '$stateStr $side $mode ${stock.symbol} x$quantity @ ₹$price';
  }
}

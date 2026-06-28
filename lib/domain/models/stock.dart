import 'package:hive/hive.dart';

part 'stock.g.dart';

@HiveType(typeId: 0)
class Stock {
  @HiveField(0)
  final String instrumentKey;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String exchange;

  @HiveField(4)
  final String? instrumentType;

  Stock({
    required this.instrumentKey,
    required this.symbol,
    required this.name,
    required this.exchange,
    this.instrumentType,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      instrumentKey: json['instrument_key'] ?? '',
      symbol: json['trading_symbol'] ?? json['symbol'] ?? '',
      name: json['name'] ?? json['company_name'] ?? '',
      exchange: json['exchange'] ?? '',
      instrumentType: json['instrument_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instrument_key': instrumentKey,
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'instrument_type': instrumentType,
    };
  }

  @override
  String toString() => '$symbol ($exchange)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          instrumentKey == other.instrumentKey;

  @override
  int get hashCode => instrumentKey.hashCode;
}

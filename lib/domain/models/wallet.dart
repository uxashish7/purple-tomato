import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 3)
class Wallet {
  @HiveField(0)
  double balance;

  @HiveField(1)
  final double initialBalance;

  Wallet({
    required this.balance,
    required this.initialBalance,
  });

  /// Check if user can afford a purchase
  bool canAfford(double amount) => balance >= amount;

  /// Validate and deduct balance for a buy order
  bool deduct(double amount) {
    if (!canAfford(amount)) return false;
    balance -= amount;
    return true;
  }

  /// Add funds back (for sell orders)
  void credit(double amount) {
    balance += amount;
  }

  /// Reset to initial balance
  void reset() {
    balance = initialBalance;
  }

  /// Get profit/loss from initial balance
  double get pnl => balance - initialBalance;

  /// Get profit/loss percentage
  double get pnlPercent => (pnl / initialBalance) * 100;

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'initialBalance': initialBalance,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: json['balance'].toDouble(),
      initialBalance: json['initialBalance'].toDouble(),
    );
  }

  factory Wallet.initial(double initialBalance) {
    return Wallet(
      balance: initialBalance,
      initialBalance: initialBalance,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../services/hive_service.dart';
import '../config/api_config.dart';

/// Wallet state notifier for managing virtual cash balance
class WalletNotifier extends StateNotifier<Wallet> {
  WalletNotifier() : super(HiveService.getWallet());

  /// Get current balance
  double get balance => state.balance;

  /// Get initial balance
  double get initialBalance => state.initialBalance;

  /// Check if user can afford a purchase
  bool canAfford(double amount) => state.canAfford(amount);

  /// Validate buy order
  String? validateBuyOrder(double price, int quantity) {
    final totalCost = price * quantity;
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    if (price <= 0) {
      return 'Invalid price';
    }
    
    if (!canAfford(totalCost)) {
      return 'Insufficient funds. Need ₹${totalCost.toStringAsFixed(2)} but have ₹${balance.toStringAsFixed(2)}';
    }
    
    return null; // Valid order
  }

  /// Deduct balance for buy order
  Future<bool> deductForBuy(double amount) async {
    if (state.deduct(amount)) {
      await HiveService.saveWallet(state);
      state = HiveService.getWallet(); // Refresh state
      return true;
    }
    return false;
  }

  /// Credit balance for sell order
  Future<void> creditFromSell(double amount) async {
    state.credit(amount);
    await HiveService.saveWallet(state);
    state = HiveService.getWallet(); // Refresh state
  }

  /// Reset wallet to initial balance
  Future<void> reset() async {
    await HiveService.resetAll();
    state = HiveService.getWallet();
  }

  /// Refresh from storage
  void refresh() {
    state = HiveService.getWallet();
  }
}

/// Provider for wallet state
final walletProvider = StateNotifierProvider<WalletNotifier, Wallet>((ref) {
  return WalletNotifier();
});

/// Provider for just the balance (derived)
final balanceProvider = Provider<double>((ref) {
  return ref.watch(walletProvider).balance;
});

/// Provider for formatted balance string
final formattedBalanceProvider = Provider<String>((ref) {
  final balance = ref.watch(balanceProvider);
  return '₹${_formatIndianNumber(balance)}';
});

/// Helper to format number in Indian style (lakhs, crores)
String _formatIndianNumber(double number) {
  if (number >= 10000000) {
    return '${(number / 10000000).toStringAsFixed(2)} Cr';
  } else if (number >= 100000) {
    return '${(number / 100000).toStringAsFixed(2)} L';
  } else {
    return number.toStringAsFixed(2);
  }
}

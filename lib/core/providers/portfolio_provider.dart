import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/holding.dart';
import '../models/stock.dart';
import '../models/order.dart';
import '../services/hive_service.dart';
import 'wallet_provider.dart';

/// Portfolio state notifier for managing holdings
class PortfolioNotifier extends StateNotifier<List<Holding>> {
  final Ref _ref;
  
  PortfolioNotifier(this._ref) : super(HiveService.getHoldings());

  /// Get all holdings
  List<Holding> get holdings => state;

  /// Get holding by instrument key
  Holding? getHolding(String instrumentKey) {
    try {
      return state.firstWhere((h) => h.stock.instrumentKey == instrumentKey);
    } catch (_) {
      return null;
    }
  }

  /// Check if stock is owned
  bool ownsStock(String instrumentKey) {
    return state.any((h) => h.stock.instrumentKey == instrumentKey);
  }

  /// Get quantity owned for a stock
  int getQuantityOwned(String instrumentKey) {
    final holding = getHolding(instrumentKey);
    return holding?.quantity ?? 0;
  }

  /// Execute buy order
  Future<bool> buyStock({
    required Stock stock,
    required int quantity,
    required double price,
  }) async {
    final totalCost = price * quantity;
    
    // Validate and deduct from wallet
    final walletNotifier = _ref.read(walletProvider.notifier);
    final validationError = walletNotifier.validateBuyOrder(price, quantity);
    
    if (validationError != null) {
      return false;
    }
    
    final deducted = await walletNotifier.deductForBuy(totalCost);
    if (!deducted) return false;
    
    // Update or create holding
    final existingHolding = getHolding(stock.instrumentKey);
    
    if (existingHolding != null) {
      // Average out the buy price
      existingHolding.addShares(quantity, price);
      await HiveService.saveHolding(existingHolding);
    } else {
      // Create new holding
      final newHolding = Holding(
        id: const Uuid().v4(),
        stock: stock,
        quantity: quantity,
        avgBuyPrice: price,
        purchaseDate: DateTime.now(),
      );
      await HiveService.saveHolding(newHolding);
    }
    
    // Record order
    final order = Order.buy(
      id: const Uuid().v4(),
      stock: stock,
      quantity: quantity,
      price: price,
    );
    await HiveService.addOrder(order);
    
    // Refresh state
    state = HiveService.getHoldings();
    return true;
  }

  /// Execute sell order
  Future<bool> sellStock({
    required Stock stock,
    required int quantity,
    required double price,
  }) async {
    final holding = getHolding(stock.instrumentKey);
    
    if (holding == null || holding.quantity < quantity) {
      return false;
    }
    
    final totalValue = price * quantity;
    
    // Credit wallet
    final walletNotifier = _ref.read(walletProvider.notifier);
    await walletNotifier.creditFromSell(totalValue);
    
    // Update holding
    if (holding.quantity == quantity) {
      // Sell all - remove holding
      await HiveService.removeHolding(holding.id);
    } else {
      // Partial sell
      holding.reduceShares(quantity);
      await HiveService.saveHolding(holding);
    }
    
    // Record order
    final order = Order.sell(
      id: const Uuid().v4(),
      stock: stock,
      quantity: quantity,
      price: price,
    );
    await HiveService.addOrder(order);
    
    // Refresh state
    state = HiveService.getHoldings();
    return true;
  }

  /// Calculate total invested value
  double get totalInvested {
    return state.fold(0.0, (sum, h) => sum + h.investedValue);
  }

  /// Calculate total current value based on live prices
  double totalCurrentValue(Map<String, double> livePrices) {
    return state.fold(0.0, (sum, h) {
      final livePrice = livePrices[h.stock.instrumentKey] ?? h.avgBuyPrice;
      return sum + h.currentValue(livePrice);
    });
  }

  /// Calculate total P&L
  double totalPnl(Map<String, double> livePrices) {
    return totalCurrentValue(livePrices) - totalInvested;
  }

  /// Calculate total P&L percentage
  double totalPnlPercent(Map<String, double> livePrices) {
    if (totalInvested == 0) return 0;
    return (totalPnl(livePrices) / totalInvested) * 100;
  }

  /// Refresh from storage
  void refresh() {
    state = HiveService.getHoldings();
  }

  /// Reset portfolio
  Future<void> reset() async {
    await HiveService.resetAll();
    state = [];
    _ref.read(walletProvider.notifier).refresh();
  }
}

/// Provider for portfolio state
final portfolioProvider = StateNotifierProvider<PortfolioNotifier, List<Holding>>((ref) {
  return PortfolioNotifier(ref);
});

/// Provider for orders history
final ordersProvider = Provider<List<Order>>((ref) {
  // Watch portfolio changes to trigger order refresh
  ref.watch(portfolioProvider);
  return HiveService.getOrders();
});

/// Provider for total invested value
final totalInvestedProvider = Provider<double>((ref) {
  final holdings = ref.watch(portfolioProvider);
  return holdings.fold(0.0, (sum, h) => sum + h.investedValue);
});

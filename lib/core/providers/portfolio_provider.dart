import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:purple_tomato/domain/models/holding.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/domain/models/order.dart';
import 'package:purple_tomato/core/utils/app_logger.dart';
import 'market_data_provider.dart';
import '../services/hive_service.dart';
import 'wallet_provider.dart';

/// Portfolio state notifier for managing holdings and pending order engine
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

  /// Execute instant market buy order
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
      existingHolding.addShares(quantity, price);
      await HiveService.saveHolding(existingHolding);
    } else {
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

  /// Execute instant market sell order
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
      await HiveService.removeHolding(holding.id);
    } else {
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

  /// Place a Limit Buy Order (Executes when market price drops to targetPrice)
  Future<bool> placeLimitBuy({
    required Stock stock,
    required int quantity,
    required double targetPrice,
  }) async {
    final totalCost = targetPrice * quantity;
    final walletNotifier = _ref.read(walletProvider.notifier);
    final validationError = walletNotifier.validateBuyOrder(targetPrice, quantity);
    
    if (validationError != null) return false;
    
    // Reserve cash for limit buy
    final deducted = await walletNotifier.deductForBuy(totalCost);
    if (!deducted) return false;

    final order = Order.limitBuy(
      id: const Uuid().v4(),
      stock: stock,
      quantity: quantity,
      targetPrice: targetPrice,
    );
    await HiveService.addOrder(order);
    AppLogger.info('Placed Limit Buy Order: $order', tag: 'PortfolioNotifier');
    return true;
  }

  /// Place a Limit Sell Order (Executes when market price rises to targetPrice)
  Future<bool> placeLimitSell({
    required Stock stock,
    required int quantity,
    required double targetPrice,
  }) async {
    final holding = getHolding(stock.instrumentKey);
    if (holding == null || holding.quantity < quantity) return false;

    final order = Order.limitSell(
      id: const Uuid().v4(),
      stock: stock,
      quantity: quantity,
      targetPrice: targetPrice,
    );
    await HiveService.addOrder(order);
    AppLogger.info('Placed Limit Sell Order: $order', tag: 'PortfolioNotifier');
    return true;
  }

  /// Place a Stop-Loss Order (Executes sell when price drops to triggerPrice)
  Future<bool> placeStopLoss({
    required Stock stock,
    required int quantity,
    required double triggerPrice,
  }) async {
    final holding = getHolding(stock.instrumentKey);
    if (holding == null || holding.quantity < quantity) return false;

    final order = Order.stopLoss(
      id: const Uuid().v4(),
      stock: stock,
      quantity: quantity,
      triggerPrice: triggerPrice,
    );
    await HiveService.addOrder(order);
    AppLogger.info('Placed Stop-Loss Order: $order', tag: 'PortfolioNotifier');
    return true;
  }

  /// Automated Matching Engine: Evaluates pending orders against live stock quotes
  Future<void> processPendingOrders(Map<String, double> livePrices) async {
    final allOrders = HiveService.getOrders();
    final pendingOrders = allOrders.where((o) => o.isPending).toList();

    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      final currentPrice = livePrices[order.stock.instrumentKey];
      if (currentPrice == null || currentPrice <= 0) continue;

      bool shouldExecute = false;

      if (order.isLimit && order.isBuy) {
        // Limit Buy triggers if live price drops to or below target price
        shouldExecute = currentPrice <= (order.targetPrice ?? order.price);
      } else if (order.isLimit && order.isSell) {
        // Limit Sell triggers if live price rises to or above target price
        shouldExecute = currentPrice >= (order.targetPrice ?? order.price);
      } else if (order.isStopLoss) {
        // Stop Loss triggers if live price falls to or below trigger price
        shouldExecute = currentPrice <= (order.triggerPrice ?? order.price);
      }

      if (shouldExecute) {
        AppLogger.info('Matching Engine Triggered for Order ${order.id}: ${order.stock.symbol} @ ₹$currentPrice', tag: 'PortfolioNotifier');
        
        if (order.isBuy) {
          // Add shares to holding (cash was already reserved at placement)
          final existingHolding = getHolding(order.stock.instrumentKey);
          if (existingHolding != null) {
            existingHolding.addShares(order.quantity, currentPrice);
            await HiveService.saveHolding(existingHolding);
          } else {
            final newHolding = Holding(
              id: const Uuid().v4(),
              stock: order.stock,
              quantity: order.quantity,
              avgBuyPrice: currentPrice,
              purchaseDate: DateTime.now(),
            );
            await HiveService.saveHolding(newHolding);
          }
        } else {
          // Sell order: Credit wallet and update holding
          final walletNotifier = _ref.read(walletProvider.notifier);
          await walletNotifier.creditFromSell(currentPrice * order.quantity);

          final holding = getHolding(order.stock.instrumentKey);
          if (holding != null) {
            if (holding.quantity <= order.quantity) {
              await HiveService.removeHolding(holding.id);
            } else {
              holding.reduceShares(order.quantity);
              await HiveService.saveHolding(holding);
            }
          }
        }

        // Mark order executed
        final updatedOrder = order.copyWith(statusIndex: 0, price: currentPrice);
        await HiveService.addOrder(updatedOrder);
        state = HiveService.getHoldings();
      }
    }
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
  final notifier = PortfolioNotifier(ref);
  // Listen to live prices to continuously evaluate pending orders
  ref.listen<Map<String, double>>(livePricesProvider, (_, livePrices) {
    notifier.processPendingOrders(livePrices);
  });
  return notifier;
});

/// Provider for orders history
final ordersProvider = Provider<List<Order>>((ref) {
  ref.watch(portfolioProvider);
  return HiveService.getOrders();
});

/// Provider for total invested value
final totalInvestedProvider = Provider<double>((ref) {
  final holdings = ref.watch(portfolioProvider);
  return holdings.fold(0.0, (sum, h) => sum + h.investedValue);
});

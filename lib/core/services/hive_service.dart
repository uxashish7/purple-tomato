import 'package:hive_flutter/hive_flutter.dart';
import '../models/stock.dart';
import '../models/holding.dart';
import '../models/order.dart';
import '../models/wallet.dart';
import '../config/api_config.dart';

/// Service for managing Hive local storage
class HiveService {
  static const String _walletBoxName = 'wallet';
  static const String _portfolioBoxName = 'portfolio';
  static const String _ordersBoxName = 'orders';
  static const String _watchlistBoxName = 'watchlist';
  static const String _settingsBoxName = 'settings';

  static late Box<Wallet> _walletBox;
  static late Box<Holding> _portfolioBox;
  static late Box<Order> _ordersBox;
  static late Box<Stock> _watchlistBox;
  static late Box<dynamic> _settingsBox;

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    // Register type adapters
    Hive.registerAdapter(StockAdapter());
    Hive.registerAdapter(HoldingAdapter());
    Hive.registerAdapter(OrderAdapter());
    Hive.registerAdapter(WalletAdapter());

    // Open boxes
    _walletBox = await Hive.openBox<Wallet>(_walletBoxName);
    _portfolioBox = await Hive.openBox<Holding>(_portfolioBoxName);
    _ordersBox = await Hive.openBox<Order>(_ordersBoxName);
    _watchlistBox = await Hive.openBox<Stock>(_watchlistBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Initialize wallet if not exists
    if (_walletBox.isEmpty) {
      await _walletBox.put(
        'main',
        Wallet.initial(ApiConfig.initialWalletBalance),
      );
    }
  }

  // ============ WALLET OPERATIONS ============

  /// Get current wallet
  static Wallet getWallet() {
    return _walletBox.get('main') ??
        Wallet.initial(ApiConfig.initialWalletBalance);
  }

  /// Save wallet
  static Future<void> saveWallet(Wallet wallet) async {
    await _walletBox.put('main', wallet);
  }

  /// Get current balance
  static double getBalance() => getWallet().balance;

  /// Deduct from balance (for buy orders)
  static Future<bool> deductBalance(double amount) async {
    final wallet = getWallet();
    if (wallet.deduct(amount)) {
      await saveWallet(wallet);
      return true;
    }
    return false;
  }

  /// Credit balance (for sell orders)
  static Future<void> creditBalance(double amount) async {
    final wallet = getWallet();
    wallet.credit(amount);
    await saveWallet(wallet);
  }

  // ============ PORTFOLIO OPERATIONS ============

  /// Get all holdings
  static List<Holding> getHoldings() => _portfolioBox.values.toList();

  /// Get holding by stock instrument key
  static Holding? getHolding(String instrumentKey) {
    try {
      return _portfolioBox.values.firstWhere(
        (h) => h.stock.instrumentKey == instrumentKey,
      );
    } catch (_) {
      return null;
    }
  }

  /// Add or update a holding
  static Future<void> saveHolding(Holding holding) async {
    await _portfolioBox.put(holding.id, holding);
  }

  /// Remove a holding
  static Future<void> removeHolding(String id) async {
    await _portfolioBox.delete(id);
  }

  // ============ ORDERS OPERATIONS ============

  /// Get all orders
  static List<Order> getOrders() {
    final orders = _ordersBox.values.toList();
    orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return orders;
  }

  /// Add a new order
  static Future<void> addOrder(Order order) async {
    await _ordersBox.put(order.id, order);
  }

  /// Get orders for a specific stock
  static List<Order> getOrdersForStock(String instrumentKey) {
    return _ordersBox.values
        .where((o) => o.stock.instrumentKey == instrumentKey)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ============ WATCHLIST OPERATIONS ============

  /// Get all watchlist stocks
  static List<Stock> getWatchlist() => _watchlistBox.values.toList();

  /// Add stock to watchlist
  static Future<void> addToWatchlist(Stock stock) async {
    await _watchlistBox.put(stock.instrumentKey, stock);
  }

  /// Remove stock from watchlist
  static Future<void> removeFromWatchlist(String instrumentKey) async {
    await _watchlistBox.delete(instrumentKey);
  }

  /// Check if stock is in watchlist
  static bool isInWatchlist(String instrumentKey) {
    return _watchlistBox.containsKey(instrumentKey);
  }

  // ============ SETTINGS OPERATIONS ============

  /// Get access token
  static String? getAccessToken() {
    return _settingsBox.get('access_token');
  }

  /// Save access token
  static Future<void> saveAccessToken(String token) async {
    await _settingsBox.put('access_token', token);
  }

  /// Clear access token
  static Future<void> clearAccessToken() async {
    await _settingsBox.delete('access_token');
  }

  /// Check if using mock mode
  static bool get isMockMode => getAccessToken() == null;

  // ============ RESET OPERATIONS ============

  /// Reset all data and restore initial balance
  static Future<void> resetAll() async {
    await _portfolioBox.clear();
    await _ordersBox.clear();
    await _watchlistBox.clear();
    await _walletBox.put(
      'main',
      Wallet.initial(ApiConfig.initialWalletBalance),
    );
  }

  /// Close all boxes
  static Future<void> close() async {
    await _walletBox.close();
    await _portfolioBox.close();
    await _ordersBox.close();
    await _watchlistBox.close();
    await _settingsBox.close();
  }
}

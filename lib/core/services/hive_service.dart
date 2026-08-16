import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/domain/models/holding.dart';
import 'package:purple_tomato/domain/models/order.dart';
import 'package:purple_tomato/domain/models/wallet.dart';
import '../config/api_config.dart';
// Conditional import: dart:html only exists on Flutter Web.
// On native (iOS/Android/Desktop) this file is never loaded.
// ignore: avoid_web_libraries_in_flutter
import 'package:purple_tomato/core/utils/web_storage_stub.dart'
    if (dart.library.html) 'package:purple_tomato/core/utils/web_storage.dart';

/// Service for managing Hive local storage
class HiveService {
  static const String _walletBoxName = 'wallet';
  static const String _portfolioBoxName = 'portfolio';
  static const String _ordersBoxName = 'orders';
  static const String _watchlistBoxName = 'watchlist';

  // Secure storage for sensitive tokens — native only
  static const _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'upstox_access_token';
  // Fixed localStorage key used on Web (stable across Vercel deployments)
  static const String _webTokenKey = 'pt_upstox_token';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static late Box<Wallet> _walletBox;
  static late Box<Holding> _portfolioBox;
  static late Box<Order> _ordersBox;
  static late Box<Stock> _watchlistBox;

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

    // Initialize wallet if not exists
    if (_walletBox.isEmpty) {
      await _walletBox.put(
        'main',
        Wallet.initial(ApiConfig.initialWalletBalance),
      );
    }

    _isInitialized = true;
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
    } on StateError {
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

  // ============ SETTINGS / AUTH TOKEN OPERATIONS ============
  // On Web   : stored in window.localStorage with the fixed key 'pt_upstox_token'.
  //            This key is stable across Vercel deployments (unlike flutter_secure_storage
  //            which derives its key from the JS bundle hash — changing every deploy).
  // On Native: stored in flutter_secure_storage (encrypted Keychain / Keystore).

  /// Get access token
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      try {
        final val = WebStorage.read(_webTokenKey);
        return (val == null || val.isEmpty) ? null : val;
      } catch (_) {
        return null;
      }
    }
    return _secureStorage.read(key: _accessTokenKey);
  }

  /// Save access token
  static Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      try {
        WebStorage.write(_webTokenKey, token);
      } catch (_) {}
      return;
    }
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  /// Clear access token
  static Future<void> clearAccessToken() async {
    if (kIsWeb) {
      try {
        WebStorage.remove(_webTokenKey);
      } catch (_) {}
      return;
    }
    await _secureStorage.delete(key: _accessTokenKey);
  }

  /// Check if in mock mode (no access token stored)
  static Future<bool> get isMockMode async {
    final token = await getAccessToken();
    return token == null || token.isEmpty;
  }

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
    _isInitialized = false;
  }
}

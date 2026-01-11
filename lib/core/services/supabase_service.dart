import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/portfolio_snapshot.dart';

/// Service for managing Supabase database operations
class SupabaseService {
  static SupabaseClient? _client;
  static String? _deviceId;
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'purple_tomato_device_id';

  /// Supabase configuration
  static const String _supabaseUrl = 'https://bbsbjjumkussuifslbnr.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJic2JqanVta3Vzc3VpZnNsYm5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNzYwNDAsImV4cCI6MjA4MzY1MjA0MH0.VjktuRHK41mJN-A1U6ptP2yIMpJ6G7rYGWXbyODUc70';

  /// Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Get device ID
  static String get deviceId {
    if (_deviceId == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _deviceId!;
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _deviceId = await _getOrCreateDeviceId();
      debugPrint('SupabaseService initialized with device ID: $_deviceId');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
      // Don't throw - app should still work without Supabase
    }
  }

  /// Get or create a unique device ID
  static Future<String> _getOrCreateDeviceId() async {
    String? storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null) {
      return storedId;
    }
    
    // Generate new UUID for this device
    final newId = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: newId);
    return newId;
  }

  /// Check if Supabase is available
  static bool get isAvailable => _client != null;

  /// Save a portfolio snapshot
  static Future<bool> saveSnapshot({
    required double totalValue,
    required double cashBalance,
    required double investedAmount,
    required double holdingsValue,
  }) async {
    if (!isAvailable) {
      debugPrint('Supabase not available, skipping snapshot save');
      return false;
    }

    try {
      await client.from('portfolio_snapshots').insert({
        'device_id': deviceId,
        'total_value': totalValue,
        'cash_balance': cashBalance,
        'invested_amount': investedAmount,
        'holdings_value': holdingsValue,
      });
      debugPrint('Portfolio snapshot saved successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to save portfolio snapshot: $e');
      return false;
    }
  }

  /// Get snapshots for a time period
  static Future<List<PortfolioSnapshot>> getSnapshots({
    required Duration period,
  }) async {
    if (!isAvailable) {
      return [];
    }

    try {
      final since = DateTime.now().subtract(period);
      final response = await client
          .from('portfolio_snapshots')
          .select()
          .eq('device_id', deviceId)
          .gte('timestamp', since.toIso8601String())
          .order('timestamp');

      return (response as List)
          .map((e) => PortfolioSnapshot.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Failed to get snapshots: $e');
      return [];
    }
  }

  /// Get the most recent snapshot
  static Future<PortfolioSnapshot?> getLatestSnapshot() async {
    if (!isAvailable) {
      return null;
    }

    try {
      final response = await client
          .from('portfolio_snapshots')
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) {
        return null;
      }
      return PortfolioSnapshot.fromJson(response.first);
    } catch (e) {
      debugPrint('Failed to get latest snapshot: $e');
      return null;
    }
  }

  /// Check if we should save a new snapshot (max once per hour)
  static Future<bool> shouldSaveSnapshot() async {
    final latest = await getLatestSnapshot();
    if (latest == null) {
      return true; // No snapshots yet, should save
    }
    
    final hoursSinceLastSnapshot = DateTime.now().difference(latest.timestamp).inHours;
    return hoursSinceLastSnapshot >= 1;
  }

  /// Save snapshot if needed (rate limited)
  static Future<bool> saveSnapshotIfNeeded({
    required double totalValue,
    required double cashBalance,
    required double investedAmount,
    required double holdingsValue,
  }) async {
    if (!await shouldSaveSnapshot()) {
      debugPrint('Snapshot rate limited, skipping');
      return false;
    }
    
    return saveSnapshot(
      totalValue: totalValue,
      cashBalance: cashBalance,
      investedAmount: investedAmount,
      holdingsValue: holdingsValue,
    );
  }
}

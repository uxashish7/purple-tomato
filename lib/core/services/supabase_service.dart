import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../models/portfolio_snapshot.dart';

/// Service for managing Supabase database and authentication
class SupabaseService {
  static SupabaseClient? _client;
  static String? _deviceId;
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'purple_tomato_device_id';

  /// Supabase configuration
  static const String _supabaseUrl = 'https://bbsbjjumkussuifslbnr.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJic2JqanVta3Vzc3VpZnNsYm5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwNzYwNDAsImV4cCI6MjA4MzY1MjA0MH0.VjktuRHK41mJN-A1U6ptP2yIMpJ6G7rYGWXbyODUc70';
  
  // Google OAuth Web Client ID from Google Cloud Console
  static const String _googleWebClientId = '933329104418-trk7cpj3bt59kklei793cqs3o2s6euo0.apps.googleusercontent.com';

  /// Get Supabase client
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Get current user (if logged in)
  static User? get currentUser => _client?.auth.currentUser;
  
  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
  
  /// Get user ID (for database queries) - uses auth user ID if logged in, else device ID
  static String get userId {
    if (currentUser != null) {
      return currentUser!.id;
    }
    if (_deviceId != null) {
      return _deviceId!;
    }
    throw Exception('SupabaseService not initialized. Call initialize() first.');
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
      debugPrint('SupabaseService initialized');
      if (currentUser != null) {
        debugPrint('User logged in: ${currentUser!.email}');
      } else {
        debugPrint('Using device ID: $_deviceId');
      }
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  }

  /// Get or create a unique device ID
  static Future<String> _getOrCreateDeviceId() async {
    String? storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null) {
      return storedId;
    }
    
    final newId = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: newId);
    return newId;
  }

  /// Check if Supabase is available
  static bool get isAvailable => _client != null;

  // ============ AUTHENTICATION METHODS ============

  /// Sign in with Google
  static Future<AuthResponse?> signInWithGoogle() async {
    if (!isAvailable) return null;
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: _googleWebClientId,
        scopes: ['email'],
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in cancelled');
        return null;
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google auth tokens');
      }
      
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      debugPrint('Signed in as: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    if (!isAvailable) return;
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await client.auth.signOut();
      debugPrint('Signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ============ DATABASE METHODS ============

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
        'device_id': userId, // Uses user ID if logged in, else device ID
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
          .eq('device_id', userId)
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
          .eq('device_id', userId)
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
      return true;
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

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import 'package:purple_tomato/domain/models/portfolio_snapshot.dart';

/// Service for managing Supabase database and authentication
class SupabaseService {
  static SupabaseClient? _client;
  static String? _deviceId;
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'purple_tomato_device_id';

  /// Supabase configuration — loaded from dart-define environment variables.
  /// See ApiConfig and .env.example for setup instructions.
  static String get _supabaseUrl => ApiConfig.supabaseUrl;
  static String get _supabaseAnonKey => ApiConfig.supabaseAnonKey;

  // Google OAuth Web Client ID — loaded from dart-define environment variables.
  static String get _googleWebClientId => ApiConfig.googleWebClientId;

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
    if (!ApiConfig.isSupabaseConfigured) {
      debugPrint('SupabaseService: Supabase not configured (missing SUPABASE_URL or SUPABASE_ANON_KEY). Running without cloud sync.');
      return;
    }

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

  // ============ EDGE FUNCTION GATEWAY METHODS ============

  /// Invoke Supabase Edge Function to exchange Upstox OAuth code securely
  static Future<String?> exchangeUpstoxCodeViaEdgeGateway({
    required String code,
    required String redirectUri,
  }) async {
    if (!isAvailable) {
      debugPrint('Supabase not initialized. Skipping Edge Gateway call.');
      return null;
    }

    try {
      final response = await client.functions.invoke(
        'upstox-oauth',
        body: {
          'code': code,
          'redirectUri': redirectUri,
        },
      );

      final data = response.data;
      if (data != null && data['access_token'] != null) {
        return data['access_token'].toString();
      }
    } catch (e) {
      debugPrint('Edge Gateway Upstox OAuth exchange error: $e');
    }
    return null;
  }
}

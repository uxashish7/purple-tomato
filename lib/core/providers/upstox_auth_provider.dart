import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/upstox_service.dart';
import '../services/hive_service.dart';

/// Auth state for Upstox connection
enum UpstoxAuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Upstox auth state notifier
class UpstoxAuthNotifier extends StateNotifier<UpstoxAuthState> {
  final UpstoxService _service;
  String? _errorMessage;

  UpstoxAuthNotifier(this._service) : super(UpstoxAuthState.initial) {
    _checkAuthStatus();
  }

  String? get errorMessage => _errorMessage;

  /// Check current auth status
  void _checkAuthStatus() {
    if (HiveService.getAccessToken() != null) {
      state = UpstoxAuthState.authenticated;
    } else {
      state = UpstoxAuthState.unauthenticated;
    }
  }

  /// Get authorization URL for OAuth
  String getAuthorizationUrl() {
    return _service.getAuthorizationUrl();
  }

  /// Exchange authorization code for token
  Future<bool> handleAuthCallback(String code) async {
    state = UpstoxAuthState.loading;
    _errorMessage = null;

    try {
      final token = await _service.exchangeCodeForToken(code);
      
      if (token != null) {
        state = UpstoxAuthState.authenticated;
        return true;
      } else {
        _errorMessage = 'Failed to get access token';
        state = UpstoxAuthState.error;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Authentication error: $e';
      state = UpstoxAuthState.error;
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _service.logout();
    state = UpstoxAuthState.unauthenticated;
  }

  /// Skip auth (use mock mode)
  void skipAuth() {
    state = UpstoxAuthState.unauthenticated;
  }

  /// Check if authenticated
  bool get isAuthenticated => state == UpstoxAuthState.authenticated;

  /// Check if using mock mode
  bool get isMockMode => !isAuthenticated;
}

/// Provider for Upstox auth state
final upstoxAuthProvider = StateNotifierProvider<UpstoxAuthNotifier, UpstoxAuthState>((ref) {
  final service = UpstoxService();
  return UpstoxAuthNotifier(service);
});

/// Provider to check if using mock mode
final isMockModeProvider = Provider<bool>((ref) {
  final authState = ref.watch(upstoxAuthProvider);
  return authState != UpstoxAuthState.authenticated;
});

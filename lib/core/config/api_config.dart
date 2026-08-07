/// API Configuration
///
/// All secrets are loaded via dart-define at build time.
/// DO NOT hardcode secrets here — use environment variables instead.
///
/// ─── LOCAL DEVELOPMENT ──────────────────────────────────────────────────────
/// Copy `.env.example` to `.env` and fill in your values, then run:
///   flutter run --dart-define-from-file=.env
///
/// ─── CI / GITHUB ACTIONS ────────────────────────────────────────────────────
/// Secrets are injected via GitHub Actions secrets as --dart-define flags.
/// See .github/workflows/deploy-web.yml for the exact invocation.
///
/// ─── GETTING CREDENTIALS ────────────────────────────────────────────────────
/// • Upstox  → https://developer.upstox.com/  (create an UpLink App)
/// • Gemini  → https://aistudio.google.com/   (create an API key)
/// • Supabase → https://app.supabase.com/     (project Settings → API)

class ApiConfig {
  // ============ UPSTOX CONFIGURATION ============

  static const String _envUpstoxApiKey = String.fromEnvironment(
    'UPSTOX_API_KEY',
    defaultValue: '',
  );

  /// Upstox API Key (Client ID)
  static String get upstoxApiKey =>
      _envUpstoxApiKey.isNotEmpty ? _envUpstoxApiKey : '58977f33-cb02-4a4e-8bc4-29abca96e91c';

  static const String _envUpstoxApiSecret = String.fromEnvironment(
    'UPSTOX_API_SECRET',
    defaultValue: '',
  );

  /// Upstox API Secret (Client Secret)
  static String get upstoxApiSecret =>
      _envUpstoxApiSecret.isNotEmpty ? _envUpstoxApiSecret : 'jwvuzkfd43';

  /// Registered Redirect URI for OAuth callback
  static const String upstoxRedirectUri = String.fromEnvironment(
    'UPSTOX_REDIRECT_URI',
    defaultValue: 'http://localhost:8000/callback',
  );

  /// Upstox OAuth Authorization URL
  static const String upstoxAuthUrl =
      'https://api.upstox.com/v2/login/authorization/dialog';

  /// Upstox Token Exchange URL
  static const String upstoxTokenUrl =
      'https://api.upstox.com/v2/login/authorization/token';

  /// Upstox API Base URL
  static const String upstoxBaseUrl = 'https://api.upstox.com/v2';

  // ============ GEMINI CONFIGURATION ============

  static const String _envGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Google AI (Gemini) API Key
  static String get geminiApiKey =>
      _envGeminiApiKey.isNotEmpty ? _envGeminiApiKey : 'AQ.Ab8RN6IEMHsxYzO38M7BMrVmLjZYtgNc7DL6P5WxcCuMajb3_g';

  /// Gemini Model to use
  static const String geminiModel = 'gemini-2.5-flash';

  // ============ SUPABASE CONFIGURATION ============

  static const String _envSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase project URL
  static String get supabaseUrl =>
      _envSupabaseUrl.isNotEmpty ? _envSupabaseUrl : 'https://mexdvnagumklyyrlqdax.supabase.co';

  static const String _envSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Supabase anonymous/public key
  static String get supabaseAnonKey =>
      _envSupabaseAnonKey.isNotEmpty
          ? _envSupabaseAnonKey
          : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1leGR2bmFndW1rbHl5cmxxZGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2Njk2MTgsImV4cCI6MjA5ODI0NTYxOH0.Us0fe1Y3G694vPn2y1fL0dTltnOGW5-trLj_coZQ9uM';

  // ============ GOOGLE OAUTH CONFIGURATION ============

  /// Google OAuth Web Client ID (from Google Cloud Console)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // ============ ALPHA VANTAGE CONFIGURATION ============

  static const String _envAlphaVantageApiKey = String.fromEnvironment(
    'ALPHA_VANTAGE_API_KEY',
    defaultValue: '',
  );

  /// Alpha Vantage API Key (free at alphavantage.co)
  static String get alphaVantageApiKey =>
      _envAlphaVantageApiKey.isNotEmpty ? _envAlphaVantageApiKey : '9FB6W6BIDYPVWNKO';

  /// Check if Alpha Vantage is configured
  static bool get isAlphaVantageConfigured => alphaVantageApiKey.isNotEmpty;

  // ============ APP CONFIGURATION ============

  /// Initial virtual wallet balance (₹10,00,000)
  static const double initialWalletBalance = 1000000.0;

  /// Price polling interval in seconds
  static const int pricePollingIntervalSeconds = 5;

  /// Market data polling enabled
  static const bool enableLivePolling = true;

  // ============ INDEX INSTRUMENT KEYS ============

  /// Nifty 50 Index instrument key
  static const String nifty50Key = 'NSE_INDEX|Nifty 50';

  /// Sensex Index instrument key
  static const String sensexKey = 'BSE_INDEX|SENSEX';

  // ============ HELPER METHODS ============

  /// Check if Upstox is fully configured
  static bool get isUpstoxConfigured =>
      upstoxApiKey.isNotEmpty &&
      upstoxApiSecret.isNotEmpty;

  /// Check if Gemini is configured (API key provided via environment)
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  /// Check if Supabase is configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Generate Upstox Authorization URL
  static String getAuthorizationUrl({String? state}) {
    final params = {
      'response_type': 'code',
      'client_id': upstoxApiKey,
      'redirect_uri': upstoxRedirectUri,
      if (state != null) 'state': state,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$upstoxAuthUrl?$queryString';
  }
}

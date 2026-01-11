/// API Configuration Template
/// 
/// IMPORTANT: Copy this file and rename to `api_config_secrets.dart`
/// Add `api_config_secrets.dart` to your `.gitignore`
/// 
/// To get Upstox credentials:
/// 1. Go to https://developer.upstox.com/
/// 2. Create an "UpLink App"
/// 3. Copy your API Key, Secret, and set your Redirect URI
/// 
/// To get Gemini API Key:
/// 1. Go to https://aistudio.google.com/
/// 2. Create an API key

class ApiConfig {
  // ============ UPSTOX CONFIGURATION ============
  
  /// Your Upstox API Key (Client ID)
  static const String upstoxApiKey = 'YOUR_UPSTOX_API_KEY';
  
  /// Your Upstox API Secret (Client Secret)
  static const String upstoxApiSecret = 'YOUR_UPSTOX_API_SECRET';
  
  /// Your registered Redirect URI
  /// Example: 'https://yourapp.com/callback' or custom scheme 'myapp://callback'
  static const String upstoxRedirectUri = 'YOUR_REDIRECT_URI';
  
  /// Upstox OAuth Authorization URL
  static const String upstoxAuthUrl = 'https://api.upstox.com/v2/login/authorization/dialog';
  
  /// Upstox Token Exchange URL
  static const String upstoxTokenUrl = 'https://api.upstox.com/v2/login/authorization/token';
  
  /// Upstox API Base URL
  static const String upstoxBaseUrl = 'https://api.upstox.com/v2';
  
  // ============ GEMINI CONFIGURATION ============
  
  /// Your Google AI (Gemini) API Key - loaded from environment variable
  /// Set via: flutter build web --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  /// Gemini Model to use
  static const String geminiModel = 'gemini-2.5-flash';
  
  // ============ ALPHA VANTAGE CONFIGURATION ============
  
  /// Your Alpha Vantage API Key (free at alphavantage.co)
  static const String alphaVantageApiKey = 'IT660JF4J28F5M11';
  
  /// Check if Alpha Vantage is configured
  static bool get isAlphaVantageConfigured =>
      alphaVantageApiKey != 'YOUR_ALPHA_VANTAGE_API_KEY';
  
  // ============ ANGEL ONE SMARTAPI CONFIGURATION ============
  // Get credentials at: https://smartapi.angelbroking.com
  
  /// Your Angel One API Key
  static const String angelOneApiKey = 'YOUR_ANGEL_ONE_API_KEY';
  
  /// Your Angel One Client ID (trading account ID)
  static const String angelOneClientId = 'YOUR_CLIENT_ID';
  
  /// Your Angel One Password
  static const String angelOnePassword = 'YOUR_PASSWORD';
  
  /// Your TOTP Secret (for 2FA - optional, can use authenticator app instead)
  static const String angelOneTotpSecret = '';
  
  /// Check if Angel One is configured
  static bool get isAngelOneConfigured =>
      angelOneApiKey != 'YOUR_ANGEL_ONE_API_KEY' &&
      angelOneClientId != 'YOUR_CLIENT_ID';
  
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
  
  /// Check if Upstox is configured
  static bool get isUpstoxConfigured =>
      upstoxApiKey != 'YOUR_UPSTOX_API_KEY' &&
      upstoxApiSecret != 'YOUR_UPSTOX_API_SECRET' &&
      upstoxRedirectUri != 'YOUR_REDIRECT_URI';
  
  /// Check if Gemini is configured (API key provided via environment)
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
  
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

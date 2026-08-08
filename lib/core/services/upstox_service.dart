import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import 'package:purple_tomato/domain/models/market_quote.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

/// Service for interacting with Upstox API
class UpstoxService {
  final Dio _dio;
  
  UpstoxService() : _dio = Dio() {
    _dio.options.baseUrl = ApiConfig.upstoxBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = HiveService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 - Token expired
        if (error.response?.statusCode == 401) {
          HiveService.clearAccessToken();
        }
        handler.next(error);
      },
    ));
  }

  /// Check if user is authenticated with Upstox
  Future<bool> get isAuthenticated async {
    final token = await HiveService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get authorization URL for OAuth login
  String getAuthorizationUrl({String? state}) {
    return ApiConfig.getAuthorizationUrl(state: state);
  }

  /// Exchange authorization code for access token
  Future<String?> exchangeCodeForToken(String code) async {
    debugPrint('UpstoxService: Starting token exchange...');
    debugPrint('UpstoxService: redirect_uri = ${ApiConfig.upstoxRedirectUri}');

    // ── Path 1: Supabase Edge Function (preferred — keeps secrets server-side) ──
    if (SupabaseService.isAvailable) {
      debugPrint('UpstoxService: Trying Supabase Edge Function...');
      try {
        final token = await SupabaseService.exchangeUpstoxCodeViaEdgeGateway(
          code: code,
          redirectUri: ApiConfig.upstoxRedirectUri,
        );
        if (token != null && token.isNotEmpty) {
          debugPrint('UpstoxService: Edge Function succeeded ✅');
          await HiveService.saveAccessToken(token);
          return token;
        }
        debugPrint('UpstoxService: Edge Function returned null — falling back');
      } catch (e) {
        debugPrint('UpstoxService: Edge Function error: $e — falling back');
      }
    } else {
      debugPrint('UpstoxService: Supabase not available — skipping Edge Function');
    }

    // ── Path 2: Server-side proxy (Web) or direct API call (native) ──
    // IMPORTANT: We use a fresh Dio WITHOUT baseUrl here.
    // The main _dio instance has baseUrl = 'https://api.upstox.com/v2',
    // which would corrupt relative paths like '/api/upstox-token'.
    final String tokenUrl;
    if (kIsWeb) {
      // Uri.base.origin gives us the current Vercel deployment origin dynamically.
      // Works for both production (purple-tomato-lyart.vercel.app)
      // and feature branch previews (purple-tomato-xyz.vercel.app).
      final origin = Uri.base.origin;
      tokenUrl = '$origin/api/upstox-token';
      debugPrint('UpstoxService: Using Vercel proxy: $tokenUrl');
    } else {
      tokenUrl = ApiConfig.upstoxTokenUrl;
      debugPrint('UpstoxService: Using direct Upstox API: $tokenUrl');
    }

    try {
      final tokenDio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      final response = await tokenDio.post(
        tokenUrl,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
        ),
        data: {
          'code': code,
          'client_id': ApiConfig.upstoxApiKey,
          'client_secret': ApiConfig.upstoxApiSecret,
          'redirect_uri': ApiConfig.upstoxRedirectUri,
          'grant_type': 'authorization_code',
        },
      );

      debugPrint('UpstoxService: Response status: ${response.statusCode}');
      debugPrint('UpstoxService: Response body: ${response.data}');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['access_token'] != null) {
        final token = response.data['access_token'] as String;
        await HiveService.saveAccessToken(token);
        debugPrint('UpstoxService: Token exchange succeeded ✅');
        return token;
      }

      // Extract a meaningful error message from Upstox response
      String errorDetail = 'HTTP ${response.statusCode}';
      if (response.data is Map) {
        if (response.data['errors'] is List && (response.data['errors'] as List).isNotEmpty) {
          final e = response.data['errors'][0];
          errorDetail = '${e['error_code'] ?? ''}: ${e['message'] ?? ''}';
        } else if (response.data['error'] != null) {
          errorDetail = response.data['error'].toString();
        } else if (response.data['message'] != null) {
          errorDetail = response.data['message'].toString();
        }
      }
      throw Exception('Token exchange failed — $errorDetail');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message} (type: ${e.type})');
    }
  }

  /// Search stocks by query
  Future<List<Stock>> searchStocks(String query) async {
    if (!await isAuthenticated) {
      return _getMockSearchResults(query);
    }

    try {
      final response = await _dio.get(
        '/market-quote/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Stock.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('UpstoxService: searchStocks error: ${e.runtimeType}');
      return _getMockSearchResults(query);
    }
  }

  /// Get LTP (Last Traded Price) for instruments
  Future<Map<String, MarketQuote>> getLiveQuotes(List<String> instrumentKeys) async {
    if (instrumentKeys.isEmpty) return {};

    if (!await isAuthenticated) {
      return _getMockQuotes(instrumentKeys);
    }

    try {
      final symbolParam = instrumentKeys.join(',');
      final response = await _dio.get(
        '/market-quote/ltp',
        queryParameters: {'symbol': symbolParam},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'];
        final Map<String, MarketQuote> quotes = {};

        data.forEach((key, value) {
          quotes[key] = MarketQuote.fromUpstoxJson(key, value);
        });

        return quotes;
      }
      return {};
    } catch (e) {
      debugPrint('UpstoxService: getLiveQuotes error: ${e.runtimeType}');
      return _getMockQuotes(instrumentKeys);
    }
  }

  /// Get full market quote for instruments
  Future<Map<String, MarketQuote>> getFullQuotes(List<String> instrumentKeys) async {
    if (instrumentKeys.isEmpty) return {};

    if (!await isAuthenticated) {
      return _getMockQuotes(instrumentKeys);
    }

    try {
      final symbolParam = instrumentKeys.join(',');
      final response = await _dio.get(
        '/market-quote/quotes',
        queryParameters: {'symbol': symbolParam},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'];
        final Map<String, MarketQuote> quotes = {};

        data.forEach((key, value) {
          quotes[key] = MarketQuote.fromUpstoxJson(key, value);
        });

        return quotes;
      }
      return {};
    } catch (e) {
      debugPrint('UpstoxService: getFullQuotes error: ${e.runtimeType}');
      return _getMockQuotes(instrumentKeys);
    }
  }

  /// Get index quotes (Nifty 50, Sensex)
  Future<List<IndexQuote>> getIndexQuotes() async {
    if (!await isAuthenticated) {
      return _getMockIndexQuotes();
    }

    try {
      final indices = [ApiConfig.nifty50Key, ApiConfig.sensexKey];
      final symbolParam = indices.join(',');

      final response = await _dio.get(
        '/market-quote/ltp',
        queryParameters: {'symbol': symbolParam},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> data = response.data['data'];
        final List<IndexQuote> quotes = [];

        data.forEach((key, value) {
          final upperKey = key.toUpperCase();
          if (upperKey.contains('NIFTY') && !quotes.any((q) => q.name == 'NIFTY 50')) {
            quotes.add(IndexQuote.fromUpstoxJson(
              'NIFTY 50',
              ApiConfig.nifty50Key,
              value is Map<String, dynamic> ? value : {},
            ));
          } else if (upperKey.contains('SENSEX') && !quotes.any((q) => q.name == 'SENSEX')) {
            quotes.add(IndexQuote.fromUpstoxJson(
              'SENSEX',
              ApiConfig.sensexKey,
              value is Map<String, dynamic> ? value : {},
            ));
          }
        });

        if (quotes.isNotEmpty) {
          return quotes;
        }
      }
      return _getMockIndexQuotes();
    } catch (e) {
      debugPrint('UpstoxService: getIndexQuotes error: $e');
      return _getMockIndexQuotes();
    }
  }


  /// Logout - clear access token
  Future<void> logout() async {
    await HiveService.clearAccessToken();
  }

  // ============ MOCK DATA FOR TESTING ============

  List<Stock> _getMockSearchResults(String query) {
    final mockStocks = [
      // NIFTY 50 Stocks
      Stock(instrumentKey: 'NSE_EQ|INE002A01018', symbol: 'RELIANCE', name: 'Reliance Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE467B01029', symbol: 'TCS', name: 'Tata Consultancy Services Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE009A01021', symbol: 'INFY', name: 'Infosys Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE040A01034', symbol: 'HDFCBANK', name: 'HDFC Bank Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE090A01021', symbol: 'ICICIBANK', name: 'ICICI Bank Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE585B01010', symbol: 'MARUTI', name: 'Maruti Suzuki India Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE018A01030', symbol: 'WIPRO', name: 'Wipro Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE154A01025', symbol: 'ITC', name: 'ITC Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE628A01036', symbol: 'SUNPHARMA', name: 'Sun Pharmaceutical Industries', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE081A01020', symbol: 'SBIN', name: 'State Bank of India', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE030A01027', symbol: 'HINDUNILVR', name: 'Hindustan Unilever Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE066A01029', symbol: 'BHARTIARTL', name: 'Bharti Airtel Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE176A01046', symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE118A01012', symbol: 'LT', name: 'Larsen & Toubro Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE019A01038', symbol: 'HCLTECH', name: 'HCL Technologies Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE152A01029', symbol: 'AXISBANK', name: 'Axis Bank Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE047A01021', symbol: 'ASIANPAINT', name: 'Asian Paints Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE021A01026', symbol: 'TATASTEEL', name: 'Tata Steel Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE155A01022', symbol: 'BAJFINANCE', name: 'Bajaj Finance Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE885A01032', symbol: 'BAJFINSV', name: 'Bajaj Finserv Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE917I01010', symbol: 'ADANIENT', name: 'Adani Enterprises Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE216A01030', symbol: 'ADANIPORTS', name: 'Adani Ports and SEZ Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE522F01014', symbol: 'TITAN', name: 'Titan Company Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE101A01026', symbol: 'NESTLEIND', name: 'Nestle India Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE239A01024', symbol: 'NTPC', name: 'NTPC Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE020B01018', symbol: 'POWERGRID', name: 'Power Grid Corporation', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE010A01019', symbol: 'ONGC', name: 'Oil and Natural Gas Corporation', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE129A01019', symbol: 'GRASIM', name: 'Grasim Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE079A01024', symbol: 'TECHM', name: 'Tech Mahindra Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE758E01017', symbol: 'JSWSTEEL', name: 'JSW Steel Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE238A01034', symbol: 'M&M', name: 'Mahindra & Mahindra Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE001A01036', symbol: 'TATAMOTORS', name: 'Tata Motors Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE245A01021', symbol: 'BRITANNIA', name: 'Britannia Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE237A01028', symbol: 'ULTRACEMCO', name: 'UltraTech Cement Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE030A01027', symbol: 'DRREDDY', name: 'Dr. Reddys Laboratories', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE020A01025', symbol: 'COALINDIA', name: 'Coal India Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE528G01035', symbol: 'INDUSINDBK', name: 'IndusInd Bank Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE027A01022', symbol: 'EICHERMOT', name: 'Eicher Motors Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE012A01025', symbol: 'HINDALCO', name: 'Hindalco Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE114A01011', symbol: 'APOLLOHOSP', name: 'Apollo Hospitals Enterprise', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE436A01026', symbol: 'CIPLA', name: 'Cipla Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE062A01020', symbol: 'DIVISLAB', name: 'Divis Laboratories Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE322A01017', symbol: 'HEROMOTOCO', name: 'Hero MotoCorp Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE495A01022', symbol: 'SBILIFE', name: 'SBI Life Insurance Company', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE947Q01028', symbol: 'HDFCLIFE', name: 'HDFC Life Insurance Company', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE669E01016', symbol: 'TATACONSUM', name: 'Tata Consumer Products', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE752E01010', symbol: 'PIDILITIND', name: 'Pidilite Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE692A01016', symbol: 'SHREECEM', name: 'Shree Cement Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE688F01024', symbol: 'PAGEIND', name: 'Page Industries Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE111A01025', symbol: 'HAVELLS', name: 'Havells India Limited', exchange: 'NSE'),
      // Additional popular stocks
      Stock(instrumentKey: 'NSE_EQ|INE094A01023', symbol: 'BAJAJ-AUTO', name: 'Bajaj Auto Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE848E01016', symbol: 'BPCL', name: 'Bharat Petroleum Corporation', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE376G01013', symbol: 'IOCL', name: 'Indian Oil Corporation Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE192A01025', symbol: 'GAIL', name: 'GAIL (India) Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE213A01029', symbol: 'DLF', name: 'DLF Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE229A01017', symbol: 'GODREJCP', name: 'Godrej Consumer Products', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE208A01029', symbol: 'VEDL', name: 'Vedanta Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE038A01020', symbol: 'BANKBARODA', name: 'Bank of Baroda', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE077A01010', symbol: 'PNB', name: 'Punjab National Bank', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE917A01017', symbol: 'CANBK', name: 'Canara Bank', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE066A01029', symbol: 'BHARATFORG', name: 'Bharat Forge Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE325A01013', symbol: 'SAIL', name: 'Steel Authority of India', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE340A01012', symbol: 'TATAPOWER', name: 'Tata Power Company Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE848A01014', symbol: 'ZOMATO', name: 'Zomato Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE417T01026', symbol: 'PAYTM', name: 'One97 Communications (Paytm)', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE758T01015', symbol: 'NYKAA', name: 'FSN E-Commerce (Nykaa)', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE121A01024', symbol: 'IRCTC', name: 'Indian Railway Catering', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE323A01018', symbol: 'LTI', name: 'LTIMindtree Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE111A01017', symbol: 'MPHASIS', name: 'Mphasis Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE115A01026', symbol: 'PERSISTENT', name: 'Persistent Systems Limited', exchange: 'NSE'),
      Stock(instrumentKey: 'NSE_EQ|INE117A01022', symbol: 'COFORGE', name: 'Coforge Limited', exchange: 'NSE'),
    ];

    if (query.isEmpty) return mockStocks.take(10).toList();
    
    return mockStocks
        .where((s) =>
            s.symbol.toLowerCase().contains(query.toLowerCase()) ||
            s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Map<String, MarketQuote> _getMockQuotes(List<String> instrumentKeys) {
    final mockPrices = {
      // NIFTY 50 & Popular stocks with realistic prices
      'NSE_EQ|INE002A01018': 2427.79,  // RELIANCE
      'NSE_EQ|INE467B01029': 3860.71,  // TCS
      'NSE_EQ|INE009A01021': 1498.06,  // INFY
      'NSE_EQ|INE040A01034': 1654.90,  // HDFCBANK
      'NSE_EQ|INE090A01021': 1175.02,  // ICICIBANK
      'NSE_EQ|INE585B01010': 11234.55, // MARUTI
      'NSE_EQ|INE018A01030': 296.75,   // WIPRO
      'NSE_EQ|INE154A01025': 465.30,   // ITC
      'NSE_EQ|INE628A01036': 1856.35,  // SUNPHARMA
      'NSE_EQ|INE081A01020': 790.28,   // SBIN
      'NSE_EQ|INE030A01027': 2394.23,  // HINDUNILVR
      'NSE_EQ|INE066A01029': 1580.45,  // BHARTIARTL
      'NSE_EQ|INE176A01046': 1765.50,  // KOTAKBANK
      'NSE_EQ|INE118A01012': 3645.80,  // LT
      'NSE_EQ|INE019A01038': 1890.25,  // HCLTECH
      'NSE_EQ|INE152A01029': 1125.60,  // AXISBANK
      'NSE_EQ|INE047A01021': 2890.45,  // ASIANPAINT
      'NSE_EQ|INE021A01026': 145.65,   // TATASTEEL
      'NSE_EQ|INE155A01022': 7456.90,  // BAJFINANCE
      'NSE_EQ|INE885A01032': 1678.45,  // BAJFINSV
      'NSE_EQ|INE917I01010': 2890.75,  // ADANIENT
      'NSE_EQ|INE216A01030': 1245.60,  // ADANIPORTS
      'NSE_EQ|INE522F01014': 3567.80,  // TITAN
      'NSE_EQ|INE101A01026': 2456.90,  // NESTLEIND
      'NSE_EQ|INE239A01024': 356.45,   // NTPC
      'NSE_EQ|INE020B01018': 298.75,   // POWERGRID
      'NSE_EQ|INE010A01019': 267.80,   // ONGC
      'NSE_EQ|INE129A01019': 2567.45,  // GRASIM
      'NSE_EQ|INE079A01024': 1678.90,  // TECHM
      'NSE_EQ|INE758E01017': 945.60,   // JSWSTEEL
      'NSE_EQ|INE238A01034': 2890.45,  // M&M
      'NSE_EQ|INE001A01036': 789.45,   // TATAMOTORS
      'NSE_EQ|INE245A01021': 5467.80,  // BRITANNIA
      'NSE_EQ|INE237A01028': 11234.55, // ULTRACEMCO
      'NSE_EQ|INE020A01025': 456.75,   // COALINDIA
      'NSE_EQ|INE528G01035': 1045.60,  // INDUSINDBK
      'NSE_EQ|INE027A01022': 4567.80,  // EICHERMOT
      'NSE_EQ|INE012A01025': 645.90,   // HINDALCO
      'NSE_EQ|INE114A01011': 6789.45,  // APOLLOHOSP
      'NSE_EQ|INE436A01026': 1567.80,  // CIPLA
      'NSE_EQ|INE062A01020': 5234.55,  // DIVISLAB
      'NSE_EQ|INE322A01017': 4567.90,  // HEROMOTOCO
      'NSE_EQ|INE495A01022': 1678.45,  // SBILIFE
      'NSE_EQ|INE947Q01028': 645.80,   // HDFCLIFE
      'NSE_EQ|INE669E01016': 1123.45,  // TATACONSUM
      'NSE_EQ|INE752E01010': 3045.60,  // PIDILITIND
      'NSE_EQ|INE692A01016': 28567.80, // SHREECEM
      'NSE_EQ|INE688F01024': 42345.55, // PAGEIND
      'NSE_EQ|INE111A01025': 1789.45,  // HAVELLS
      'NSE_EQ|INE094A01023': 9234.55,  // BAJAJ-AUTO
      'NSE_EQ|INE848E01016': 567.80,   // BPCL
      'NSE_EQ|INE376G01013': 145.60,   // IOCL
      'NSE_EQ|INE192A01025': 189.45,   // GAIL
      'NSE_EQ|INE213A01029': 845.60,   // DLF
      'NSE_EQ|INE229A01017': 1234.55,  // GODREJCP
      'NSE_EQ|INE208A01029': 445.80,   // VEDL
      'NSE_EQ|INE038A01020': 245.60,   // BANKBARODA
      'NSE_EQ|INE077A01010': 105.45,   // PNB
      'NSE_EQ|INE917A01017': 98.75,    // CANBK
      'NSE_EQ|INE325A01013': 125.60,   // SAIL
      'NSE_EQ|INE340A01012': 445.80,   // TATAPOWER
      'NSE_EQ|INE848A01014': 256.45,   // ZOMATO
      'NSE_EQ|INE417T01026': 845.60,   // PAYTM
      'NSE_EQ|INE758T01015': 178.90,   // NYKAA
      'NSE_EQ|INE121A01024': 890.45,   // IRCTC
      'NSE_EQ|INE323A01018': 5678.90,  // LTI
      'NSE_EQ|INE111A01017': 2890.45,  // MPHASIS
      'NSE_EQ|INE115A01026': 5456.80,  // PERSISTENT
      'NSE_EQ|INE117A01022': 7890.45,  // COFORGE
    };

    final Map<String, MarketQuote> quotes = {};
    
    // Check if market is open (9:15 AM - 3:30 PM IST, weekdays)
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;
    
    final isMarketOpen = weekday < 6 && // Not weekend
        (hour > 9 || (hour == 9 && minute >= 15)) && // After 9:15 AM
        (hour < 15 || (hour == 15 && minute <= 30)); // Before 3:30 PM
    
    for (final key in instrumentKeys) {
      final basePrice = mockPrices[key] ?? 500.0;
      
      double change;
      double price;
      
      if (isMarketOpen) {
        // Only generate price variation during market hours
        final variation = (DateTime.now().second % 10) / 100;
        final isPositive = DateTime.now().millisecond % 2 == 0;
        change = basePrice * variation * (isPositive ? 1 : -1);
        price = basePrice + change;
      } else {
        // Market closed - show static prices (previous close)
        change = 0.0;
        price = basePrice;
      }
      
      quotes[key] = MarketQuote.mock(
        instrumentKey: key,
        lastPrice: price,
        change: change,
        changePercent: (change / basePrice) * 100,
      );
    }
    
    return quotes;
  }

  List<IndexQuote> _getMockIndexQuotes() {
    return [
      IndexQuote.mock(
        name: 'NIFTY 50',
        instrumentKey: ApiConfig.nifty50Key,
        value: 22543.75,
        change: 125.50,
        changePercent: 0.56,
      ),
      IndexQuote.mock(
        name: 'SENSEX',
        instrumentKey: ApiConfig.sensexKey,
        value: 74256.80,
        change: -89.25,
        changePercent: -0.12,
      ),
    ];
  }
}

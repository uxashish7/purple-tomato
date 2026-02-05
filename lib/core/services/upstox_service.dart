import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/stock.dart';
import '../models/market_quote.dart';
import 'hive_service.dart';

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
  bool get isAuthenticated => HiveService.getAccessToken() != null;

  /// Get authorization URL for OAuth login
  String getAuthorizationUrl({String? state}) {
    return ApiConfig.getAuthorizationUrl(state: state);
  }

  /// Exchange authorization code for access token
  Future<String?> exchangeCodeForToken(String code) async {
    try {
      print('🔵 Exchanging code for token...');
      print('🔵 Code: $code');
      print('🔵 Client ID: ${ApiConfig.upstoxApiKey}');
      print('🔵 Redirect URI: ${ApiConfig.upstoxRedirectUri}');
      
      final response = await _dio.post(
        '/login/authorization/token',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => true, // Don't throw on any status code
        ),
        data: {
          'code': code,
          'client_id': ApiConfig.upstoxApiKey,
          'client_secret': ApiConfig.upstoxApiSecret,
          'redirect_uri': ApiConfig.upstoxRedirectUri,
          'grant_type': 'authorization_code',
        },
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final token = response.data['access_token'] as String;
        print('✅ Token received successfully!');
        await HiveService.saveAccessToken(token);
        return token;
      }
      
      // Log the error response from Upstox
      print('❌ Token exchange failed!');
      print('❌ Status: ${response.statusCode}');
      print('❌ Error response: ${response.data}');
      return null;
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Search stocks by query
  Future<List<Stock>> searchStocks(String query) async {
    if (!isAuthenticated) {
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
      print('Error searching stocks: $e');
      return _getMockSearchResults(query);
    }
  }

  /// Get LTP (Last Traded Price) for instruments
  Future<Map<String, MarketQuote>> getLiveQuotes(List<String> instrumentKeys) async {
    if (instrumentKeys.isEmpty) return {};
    
    if (!isAuthenticated) {
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
      print('Error fetching live quotes: $e');
      return _getMockQuotes(instrumentKeys);
    }
  }

  /// Get full market quote for instruments
  Future<Map<String, MarketQuote>> getFullQuotes(List<String> instrumentKeys) async {
    if (instrumentKeys.isEmpty) return {};
    
    if (!isAuthenticated) {
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
      print('Error fetching full quotes: $e');
      return _getMockQuotes(instrumentKeys);
    }
  }

  /// Get index quotes (Nifty 50, Sensex)
  Future<List<IndexQuote>> getIndexQuotes() async {
    if (!isAuthenticated) {
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
        
        if (data.containsKey(ApiConfig.nifty50Key)) {
          quotes.add(IndexQuote.fromUpstoxJson(
            'NIFTY 50',
            ApiConfig.nifty50Key,
            data[ApiConfig.nifty50Key],
          ));
        }
        
        if (data.containsKey(ApiConfig.sensexKey)) {
          quotes.add(IndexQuote.fromUpstoxJson(
            'SENSEX',
            ApiConfig.sensexKey,
            data[ApiConfig.sensexKey],
          ));
        }
        
        return quotes;
      }
      return _getMockIndexQuotes();
    } catch (e) {
      print('Error fetching index quotes: $e');
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

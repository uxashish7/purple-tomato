import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/market_quote.dart';
import '../models/stock.dart';

/// Yahoo Finance API Service for real Indian stock data
/// Uses the unofficial Yahoo Finance API (no API key required)
/// Uses CORS proxy for web browser compatibility
class YahooFinanceService {
  // Direct Yahoo Finance URLs
  static const String _yahooBaseUrl = 'https://query1.finance.yahoo.com/v8/finance';
  static const String _yahooSearchUrl = 'https://query1.finance.yahoo.com/v1/finance';
  
  // CORS proxy for web (using multiple fallback proxies)
  static const List<String> _corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
  ];
  
  final Dio _dio;
  int _currentProxyIndex = 0;
  
  YahooFinanceService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));

  /// Get the URL with CORS proxy if running in web
  String _getUrl(String baseUrl, String path, Map<String, dynamic>? queryParams) {
    final uri = Uri.parse('$baseUrl$path');
    final fullUri = queryParams != null 
        ? uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())))
        : uri;
    
    if (kIsWeb) {
      // Use CORS proxy for web
      return '${_corsProxies[_currentProxyIndex]}${Uri.encodeComponent(fullUri.toString())}';
    }
    return fullUri.toString();
  }

  /// Get NIFTY 50 and SENSEX quotes
  Future<List<IndexQuote>> getIndices() async {
    try {
      // Yahoo Finance symbols for Indian indices
      final symbols = ['^NSEI', '^BSESN']; // NIFTY 50 and SENSEX
      final names = ['NIFTY 50', 'SENSEX'];
      
      final results = <IndexQuote>[];
      
      for (int i = 0; i < symbols.length; i++) {
        final quote = await _getQuote(symbols[i]);
        if (quote != null && quote['regularMarketPrice'] != null) {
          results.add(IndexQuote(
            name: names[i],
            instrumentKey: symbols[i],
            value: quote['regularMarketPrice']?.toDouble() ?? 0,
            change: quote['regularMarketChange']?.toDouble() ?? 0,
            changePercent: quote['regularMarketChangePercent']?.toDouble() ?? 0,
          ));
        }
      }
      
      // Return mock if API fails
      if (results.isEmpty) {
        print('Yahoo Finance: No results, returning mock data');
        return _getMockIndices();
      }
      
      return results;
    } catch (e) {
      print('Yahoo Finance indices error: $e');
      // Try next proxy on error
      if (_currentProxyIndex < _corsProxies.length - 1) {
        _currentProxyIndex++;
        return getIndices(); // Retry with next proxy
      }
      return _getMockIndices();
    }
  }

  /// Get a single quote from Yahoo Finance
  Future<Map<String, dynamic>?> _getQuote(String symbol) async {
    try {
      final url = _getUrl(_yahooBaseUrl, '/chart/$symbol', {
        'interval': '1d',
        'range': '1d',
      });
      
      final response = await _dio.get(url);

      final data = response.data;
      if (data == null) return null;
      
      final result = data['chart']?['result'];
      if (result == null || (result as List).isEmpty) return null;
      
      final meta = result[0]['meta'];
      if (meta == null) return null;

      final regularMarketPrice = meta['regularMarketPrice']?.toDouble() ?? 0;
      final previousClose = meta['previousClose']?.toDouble() ?? 0;
      final change = regularMarketPrice - previousClose;
      final changePercent = previousClose != 0 ? (change / previousClose) * 100 : 0;

      return {
        'regularMarketPrice': regularMarketPrice,
        'regularMarketChange': change,
        'regularMarketChangePercent': changePercent,
        'previousClose': previousClose,
      };
    } catch (e) {
      print('Yahoo Finance quote error for $symbol: $e');
      return null;
    }
  }

  /// Search for stocks
  Future<List<Stock>> searchStocks(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    
    try {
      final url = _getUrl(_yahooSearchUrl, '/search', {
        'q': query,
        'quotesCount': '20',
        'newsCount': '0',
        'enableFuzzyQuery': 'false',
        'quotesQueryId': 'tss_match_phrase_query',
      });
      
      final response = await _dio.get(url);

      final data = response.data;
      if (data == null || data['quotes'] == null) return [];

      final quotes = data['quotes'] as List;
      return quotes
          .where((q) => q['exchange'] == 'NSI' || q['exchange'] == 'BSE' || 
                        q['exchDisp'] == 'NSE' || q['exchDisp'] == 'BSE')
          .map((q) {
            final symbol = (q['symbol'] ?? '').toString();
            String cleanSymbol = symbol.replaceAll('.NS', '').replaceAll('.BO', '');
            String exchange = symbol.endsWith('.BO') ? 'BSE' : 'NSE';
            
            return Stock(
              instrumentKey: symbol,
              symbol: cleanSymbol,
              name: q['longname'] ?? q['shortname'] ?? cleanSymbol,
              exchange: exchange,
              instrumentType: q['quoteType'] ?? 'EQUITY',
            );
          }).toList();
    } catch (e) {
      print('Yahoo Finance search error: $e');
      return [];
    }
  }

  /// Get live quote for a stock
  Future<MarketQuote?> getStockQuote(String symbol) async {
    try {
      // Convert to Yahoo Finance format if needed
      String yahooSymbol = symbol;
      if (!symbol.contains('.NS') && !symbol.contains('.BO') && !symbol.startsWith('^')) {
        yahooSymbol = '$symbol.NS'; // Default to NSE
      }
      
      final quote = await _getQuote(yahooSymbol);
      if (quote == null) return null;

      return MarketQuote(
        instrumentKey: symbol,
        lastPrice: quote['regularMarketPrice']?.toDouble() ?? 0,
        change: quote['regularMarketChange']?.toDouble() ?? 0,
        changePercent: quote['regularMarketChangePercent']?.toDouble() ?? 0,
        close: quote['previousClose']?.toDouble() ?? 0,
      );
    } catch (e) {
      print('Yahoo Finance stock quote error: $e');
      return null;
    }
  }

  /// Get quotes for multiple stocks
  Future<Map<String, MarketQuote>> getQuotes(List<String> symbols) async {
    final quotes = <String, MarketQuote>{};
    
    // Limit to avoid rate limiting
    final limitedSymbols = symbols.take(5).toList();
    
    for (final symbol in limitedSymbols) {
      final quote = await getStockQuote(symbol);
      if (quote != null) {
        quotes[symbol] = quote;
      }
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    return quotes;
  }

  /// Mock indices for fallback (Updated: Jan 6, 2026)
  /// Note: For live data, connect Upstox after Jan 12th
  List<IndexQuote> _getMockIndices() {
    return [
      IndexQuote.mock(
        name: 'NIFTY 50',
        instrumentKey: '^NSEI',
        value: 26178.70,  // Jan 6, 2026 current
        change: 146.55,
        changePercent: 0.56,
      ),
      IndexQuote.mock(
        name: 'SENSEX',
        instrumentKey: '^BSESN',
        value: 85063.34,  // Jan 6, 2026 current
        change: 478.29,
        changePercent: 0.57,
      ),
    ];
  }

  /// Get historical OHLC data for candlestick charts
  Future<List<OHLCData>> getHistoricalOHLC(String symbol, {String period = '1mo', String interval = '1d'}) async {
    try {
      // Convert to Yahoo Finance format if needed
      String yahooSymbol = symbol;
      if (!symbol.contains('.NS') && !symbol.contains('.BO') && !symbol.startsWith('^')) {
        yahooSymbol = '$symbol.NS'; // Default to NSE
      }
      
      final url = _getUrl(_yahooBaseUrl, '/chart/$yahooSymbol', {
        'interval': interval,
        'range': period,
      });
      
      final response = await _dio.get(url);
      final data = response.data;
      
      if (data == null) return _getMockOHLC();
      
      final result = data['chart']?['result'];
      if (result == null || (result as List).isEmpty) return _getMockOHLC();
      
      final timestamps = result[0]['timestamp'] as List?;
      final indicators = result[0]['indicators']?['quote']?[0];
      
      if (timestamps == null || indicators == null) return _getMockOHLC();
      
      final opens = indicators['open'] as List?;
      final highs = indicators['high'] as List?;
      final lows = indicators['low'] as List?;
      final closes = indicators['close'] as List?;
      final volumes = indicators['volume'] as List?;
      
      if (opens == null || highs == null || lows == null || closes == null) {
        return _getMockOHLC();
      }
      
      final List<OHLCData> ohlcList = [];
      
      for (int i = 0; i < timestamps.length; i++) {
        if (opens[i] != null && highs[i] != null && lows[i] != null && closes[i] != null) {
          ohlcList.add(OHLCData(
            date: DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000),
            open: (opens[i] as num).toDouble(),
            high: (highs[i] as num).toDouble(),
            low: (lows[i] as num).toDouble(),
            close: (closes[i] as num).toDouble(),
            volume: volumes != null && volumes[i] != null ? (volumes[i] as num).toDouble() : 0,
          ));
        }
      }
      
      return ohlcList.isNotEmpty ? ohlcList : _getMockOHLC();
    } catch (e) {
      print('Yahoo Finance OHLC error: $e');
      return _getMockOHLC();
    }
  }
  
  /// Generate mock OHLC data for fallback
  List<OHLCData> _getMockOHLC() {
    final List<OHLCData> mockData = [];
    final now = DateTime.now();
    double basePrice = 1500.0;
    
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final open = basePrice + (i % 3 - 1) * 10;
      final change = (i * 7 % 40) - 20;
      final high = open + (change.abs() + 15);
      final low = open - (change.abs() + 10);
      final close = open + change;
      
      mockData.add(OHLCData(
        date: date,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 1000000 + (i * 50000),
      ));
      
      basePrice = close;
    }
    
    return mockData;
  }
}

/// OHLC Data model for candlestick charts
class OHLCData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  OHLCData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });
}

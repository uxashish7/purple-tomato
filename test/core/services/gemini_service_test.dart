import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/core/services/gemini_service.dart';
import 'package:purple_tomato/domain/models/holding.dart';
import 'package:purple_tomato/domain/models/stock.dart';

void main() {
  group('GeminiService Tests', () {
    late GeminiService geminiService;

    setUp(() {
      // Assuming ApiConfig is not configured with a valid key for testing,
      // the service should fall back to mock responses.
      geminiService = GeminiService();
    });

    test('analyzePortfolio returns mock response for empty portfolio', () async {
      final analysis = await geminiService.analyzePortfolio([], {});
      
      expect(analysis, contains('Portfolio Analysis'));
      expect(analysis, contains('Your portfolio is currently empty'));
    });

    test('analyzePortfolio returns mock response with holdings', () async {
      final stock = Stock(
        instrumentKey: 'NSE_EQ|INE002A01018',
        symbol: 'RELIANCE',
        name: 'Reliance Industries',
        exchange: 'NSE',
        instrumentType: 'EQUITY',
      );
      
      final holdings = [
        Holding(
          id: 'test-1',
          stock: stock,
          quantity: 10,
          avgBuyPrice: 2500.0,
          purchaseDate: DateTime(2025, 1, 1),
        )
      ];

      final analysis = await geminiService.analyzePortfolio(holdings, {'NSE_EQ|INE002A01018': 2600.0});
      
      expect(analysis, contains('RELIANCE'));
      expect(analysis, contains('Sector Concentration Risk'));
    });

    test('getMarketInsights returns mock insights', () async {
      final insights = await geminiService.getMarketInsights();
      
      expect(insights, contains('Market Overview'));
      expect(insights, contains('IT - Strong global demand continues'));
    });

    test('chat returns appropriate mock response based on input', () async {
      final responseBank = await geminiService.chat('Tell me about bank stocks', 'Holdings: None');
      expect(responseBank, contains('Banking Sector Overview'));
      
      final responseEmpty = await geminiService.chat('analyze', 'Holdings: None');
      expect(responseEmpty, contains('Your portfolio is empty!'));
    });
  });
}

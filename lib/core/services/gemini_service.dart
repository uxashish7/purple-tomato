import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/holding.dart';

/// Service for interacting with Google Gemini AI
class GeminiService {
  GenerativeModel? _model;
  
  GeminiService() {
    if (ApiConfig.isGeminiConfigured) {
      _model = GenerativeModel(
        model: ApiConfig.geminiModel,
        apiKey: ApiConfig.geminiApiKey,
      );
    }
  }

  /// Check if Gemini is configured
  bool get isConfigured => _model != null && ApiConfig.isGeminiConfigured;

  /// Analyze portfolio for risks and recommendations
  Future<String> analyzePortfolio(List<Holding> holdings, Map<String, double> livePrices) async {
    if (!isConfigured) {
      return _getMockAnalysis(holdings);
    }

    try {
      final portfolioJson = _buildPortfolioJson(holdings, livePrices);
      
      final prompt = '''
You are a conservative financial risk manager analyzing a virtual trading portfolio for educational purposes.

The user's portfolio (in JSON format):
$portfolioJson

Please analyze this portfolio and provide:
1. **Sector Concentration Risk**: Identify if any sector is overweighted (>30% exposure)
2. **Diversification Score**: Rate from 1-10 how well diversified the portfolio is
3. **Top 3 Recommendations**: Specific, actionable advice to improve the portfolio

Keep your response concise (under 200 words), professional, and educational.
Format using bullet points for easy reading.
Do NOT provide specific buy/sell advice with target prices as this is for educational/virtual trading only.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? 'Unable to generate analysis. Please try again.';
    } catch (e) {
      print('Error analyzing portfolio with Gemini: $e');
      return _getMockAnalysis(holdings);
    }
  }

  /// Get general market insights
  Future<String> getMarketInsights() async {
    if (!isConfigured) {
      return _getMockMarketInsights();
    }

    try {
      final prompt = '''
You are a financial market analyst providing educational insights for virtual traders.

Please provide a brief market overview covering:
1. General market sentiment (bullish/bearish/neutral)
2. Key sectors to watch
3. Risk factors to be aware of

Keep your response under 150 words, professional, and educational.
Mention that this is for informational purposes only, not investment advice.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? 'Unable to generate insights. Please try again.';
    } catch (e) {
      print('Error fetching market insights: $e');
      return _getMockMarketInsights();
    }
  }

  /// Get advice for a specific stock
  Future<String> getStockAnalysis(String symbol, String name, double currentPrice) async {
    if (!isConfigured) {
      return _getMockStockAnalysis(symbol);
    }

    try {
      final prompt = '''
You are a conservative financial analyst. A virtual trader is considering $name ($symbol), currently trading at ₹$currentPrice.

Provide a brief, balanced analysis covering:
1. What type of stock is this (large-cap, mid-cap, sector)?
2. General factors a trader should consider before buying
3. Key risks to be aware of

Keep response under 100 words. This is for educational/virtual trading only - not real investment advice.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text ?? 'Unable to generate analysis.';
    } catch (e) {
      print('Error analyzing stock with Gemini: $e');
      return _getMockStockAnalysis(symbol);
    }
  }

  /// Chat with AI assistant - conversational interface
  Future<String> chat(String userMessage, String portfolioContext) async {
    print('GeminiService: isConfigured=$isConfigured');
    
    if (!isConfigured) {
      print('GeminiService: Not configured, using mock response');
      return _getMockChatResponse(userMessage, portfolioContext);
    }

    try {
      print('GeminiService: Calling Gemini API with model: ${ApiConfig.geminiModel}');
      
      final prompt = '''
You are a friendly and helpful AI trading assistant for a virtual trading app. 
You provide educational insights about stocks, markets, and trading strategies.

$portfolioContext

User message: "$userMessage"

Guidelines:
- Be conversational and helpful
- Keep responses concise (under 200 words)
- Use emojis sparingly for friendliness
- If discussing specific stocks, provide educational analysis about fundamentals, technicals, or news
- Consider the user's portfolio when giving advice
- Never give specific buy/sell prices as financial advice
- For stock analysis, discuss: company overview, sector, key metrics, recent performance, risks
- Do NOT use Markdown formatting (no **, *, #, or bullet symbols). Write in plain text only.

Respond naturally to the user's message:
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      print('GeminiService: Got response from Gemini');
      return response.text ?? 'Sorry, I couldn\'t process that. Please try again.';
    } catch (e) {
      print('GeminiService ERROR: $e');
      // Return error message instead of mock so user knows there's an issue
      return '⚠️ AI temporarily unavailable. Error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}...\n\nPlease try again in a moment.';
    }
  }

  /// Chat with AI assistant - with image/PDF attachment support
  Future<String> chatWithAttachments(
    String userMessage,
    String portfolioContext, {
    Uint8List? imageBytes,
    Uint8List? pdfBytes,  // Changed from pdfPath to pdfBytes
  }) async {
    print('GeminiService: chatWithAttachments called');
    print('  - hasImage: ${imageBytes != null}, hasPdf: ${pdfBytes != null}');
    
    if (!isConfigured) {
      print('GeminiService: Not configured, using mock response');
      return _getMockChatResponse(userMessage, portfolioContext);
    }

    try {
      final prompt = '''
You are a friendly and helpful AI trading assistant for a virtual trading app.
You provide educational insights about stocks, markets, and trading strategies.

$portfolioContext

User message: "$userMessage"

Guidelines:
- Be conversational and helpful
- Keep responses concise (under 200 words)
- Use emojis sparingly for friendliness
- If an image is attached, analyze it (e.g., stock chart patterns, trends)
- If a PDF is attached, summarize key financial data or insights
- Consider the user's portfolio when giving advice
- Never give specific buy/sell prices as financial advice
- Do NOT use Markdown formatting (no **, *, #, or bullet symbols). Write in plain text only.

Respond naturally to the user's message:
''';

      List<Content> content = [];
      
      if (imageBytes != null) {
        // Add image for analysis
        print('GeminiService: Sending image with prompt');
        content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];
      } else if (pdfBytes != null) {
        // Send PDF bytes directly (no file operations needed)
        print('GeminiService: Sending PDF with prompt');
        content = [
          Content.multi([
            TextPart(prompt),
            DataPart('application/pdf', pdfBytes),
          ])
        ];
      } else {
        content = [Content.text(prompt)];
      }
      
      final response = await _model!.generateContent(content);
      
      print('GeminiService: Got response from Gemini');
      return response.text ?? 'Sorry, I couldn\'t process that. Please try again.';
    } catch (e) {
      print('GeminiService ERROR: $e');
      return '⚠️ AI temporarily unavailable. Error: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}...\n\nPlease try again in a moment.';
    }
  }

  // ============ HELPER METHODS ============

  String _buildPortfolioJson(List<Holding> holdings, Map<String, double> livePrices) {
    final portfolioData = holdings.map((h) {
      final livePrice = livePrices[h.stock.instrumentKey] ?? h.avgBuyPrice;
      return {
        'symbol': h.stock.symbol,
        'name': h.stock.name,
        'quantity': h.quantity,
        'avgBuyPrice': h.avgBuyPrice,
        'currentPrice': livePrice,
        'investedValue': h.investedValue,
        'currentValue': h.currentValue(livePrice),
        'pnl': h.pnlAmount(livePrice),
        'pnlPercent': h.pnlPercent(livePrice),
      };
    }).toList();

    final totalInvested = holdings.fold(0.0, (sum, h) => sum + h.investedValue);
    final totalCurrent = holdings.fold(0.0, (sum, h) {
      final livePrice = livePrices[h.stock.instrumentKey] ?? h.avgBuyPrice;
      return sum + h.currentValue(livePrice);
    });

    return jsonEncode({
      'holdings': portfolioData,
      'summary': {
        'totalHoldings': holdings.length,
        'totalInvested': totalInvested,
        'totalCurrentValue': totalCurrent,
        'totalPnl': totalCurrent - totalInvested,
        'totalPnlPercent': totalInvested > 0 
            ? ((totalCurrent - totalInvested) / totalInvested) * 100 
            : 0,
      }
    });
  }

  // ============ MOCK RESPONSES ============

  String _getMockAnalysis(List<Holding> holdings) {
    if (holdings.isEmpty) {
      return '''
**Portfolio Analysis**

Your portfolio is currently empty. Here are some suggestions to get started:

• **Diversify from the start**: Consider spreading investments across 4-5 different sectors
• **Start with large-caps**: Blue-chip stocks offer stability for beginners
• **Set allocation limits**: Don't put more than 20% in any single stock

*This is a virtual trading simulation for educational purposes only.*
''';
    }

    final symbols = holdings.map((h) => h.stock.symbol).join(', ');
    return '''
**Portfolio Analysis**

📊 **Current Holdings**: $symbols

⚠️ **Sector Concentration Risk**: 
Your portfolio appears to be concentrated. Consider adding stocks from different sectors like Pharma, FMCG, or IT to balance your exposure.

📈 **Diversification Score**: 5/10
With ${holdings.length} holding(s), there's room for better diversification.

💡 **Recommendations**:
• Add defensive stocks (FMCG, Pharma) to balance volatility
• Consider limiting any single stock to 15-20% of total portfolio
• Review periodically and rebalance if any position grows too large

*This is for educational purposes only - not real investment advice.*
''';
  }

  String _getMockMarketInsights() {
    return '''
**Market Overview** (Virtual Trading Mode)

📈 **Sentiment**: Cautiously optimistic

**Sectors to Watch**:
• IT - Strong global demand continues
• Banking - Interest rate decisions key
• Auto - EV transition opportunities

⚠️ **Risk Factors**:
• Global economic uncertainty
• Currency fluctuations
• Regulatory changes

*This is for educational purposes. In live mode with Gemini configured, you'll get real-time AI insights.*
''';
  }

  String _getMockStockAnalysis(String symbol) {
    return '''
**$symbol Analysis** (Mock Mode)

This is a virtual trading simulation. Configure your Gemini API key in `api_config.dart` for AI-powered stock analysis.

**General Considerations**:
• Research the company's fundamentals
• Check recent news and announcements  
• Consider overall market conditions
• Set stop-loss levels for risk management

*For educational purposes only.*
''';
  }

  String _getMockChatResponse(String userMessage, String portfolioContext) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Check if asking about holdings/portfolio
    if (lowerMessage.contains('holding') || lowerMessage.contains('what stocks') || 
        lowerMessage.contains('my portfolio') || lowerMessage.contains('portfolio review')) {
      
      // Parse the portfolio context to extract holdings info
      if (portfolioContext.contains('Holdings: None')) {
        return "You don't have any stocks in your portfolio yet! 📭\n\nStart by searching for stocks you're interested in and make your first virtual trade. I recommend beginning with well-known companies like RELIANCE, TCS, or HDFC Bank.";
      }
      
      // Extract and display holdings from context
      return "📊 **Your Current Holdings:**\n\n$portfolioContext\n\nWould you like me to analyze your portfolio allocation or suggest any changes?";
    }
    
    if (lowerMessage.contains('analyze') || lowerMessage.contains('analysis')) {
      if (portfolioContext.contains('Holdings: None')) {
        return "Your portfolio is empty! Add some stocks first, then I can analyze your diversification, risk exposure, and suggest improvements. 📊";
      }
      return "Based on your current holdings:\n\n$portfolioContext\n\n💡 **Suggestions:**\n• Consider diversifying across different sectors\n• Keep any single stock under 20% of total portfolio\n• Balance between growth and value stocks";
    }
    
    // Sector-specific questions
    if (lowerMessage.contains('it ') || lowerMessage.contains('tech') || lowerMessage.contains('software')) {
      return "💻 **IT Sector Overview:**\n\n**Top IT Stocks to Research:**\n• **TCS** - Largest IT company, stable\n• **INFOSYS** - Strong in digital services\n• **WIPRO** - Value pick\n• **HCL TECH** - Product + services mix\n\n**Factors to Consider:**\n• Dollar-rupee movement impacts earnings\n• Global IT spending trends\n• Employee attrition rates\n\nIT sector benefits from digital transformation but can be affected by US recession fears. *For educational purposes only.*";
    }
    
    if (lowerMessage.contains('bank') || lowerMessage.contains('finance') || lowerMessage.contains('nifty bank')) {
      return "🏦 **Banking Sector Overview:**\n\n**Top Banking Stocks:**\n• **HDFC BANK** - Quality large private bank\n• **ICICI BANK** - Strong retail + digital\n• **SBI** - Largest PSU bank\n• **KOTAK BANK** - Premium valuation\n\n**Key Drivers:**\n• RBI interest rate decisions\n• Credit growth trends\n• Asset quality (NPAs)\n\n*For educational purposes only.*";
    }
    
    if (lowerMessage.contains('pharma') || lowerMessage.contains('health')) {
      return "💊 **Pharma Sector Overview:**\n\n**Top Pharma Stocks:**\n• **SUN PHARMA** - Largest by revenue\n• **CIPLA** - Strong in respiratory\n• **DR REDDY** - US generics focus\n• **DIVI'S LAB** - API manufacturer\n\n**Sector Traits:**\n• Defensive sector (less volatile)\n• USFDA approvals matter\n• Domestic demand stable\n\n*For educational purposes only.*";
    }
    
    if (lowerMessage.contains('auto') || lowerMessage.contains('electric') || lowerMessage.contains('ev')) {
      return "🚗 **Auto Sector Overview:**\n\n**Top Auto Stocks:**\n• **MARUTI** - Market leader in cars\n• **TATA MOTORS** - EV + JLR\n• **M&M** - SUVs + tractors\n• **BAJAJ AUTO** - Two-wheelers\n\n**Key Themes:**\n• EV transition opportunities\n• Chip shortage impact reducing\n• Commodity costs (steel, rubber)\n\n*For educational purposes only.*";
    }
    
    if (lowerMessage.contains('market') || lowerMessage.contains('trend') || lowerMessage.contains('sentiment') || lowerMessage.contains('nifty')) {
      return "📈 **Market Overview:**\n\nThe market sentiment is cautiously optimistic. Key sectors to watch:\n• IT - Strong global demand\n• Banking - Rate-sensitive, watch RBI moves\n• Pharma - Defensive play\n\nAlways do your research before trading!";
    }
    
    if (lowerMessage.contains('buy') || lowerMessage.contains('recommend') || lowerMessage.contains('suggest') || 
        lowerMessage.contains('invest') || lowerMessage.contains('which stock') || lowerMessage.contains('should i')) {
      return "💡 **Stock Ideas to Research:**\n\n• **Large-caps:** RELIANCE, TCS, HDFC Bank (stability)\n• **Mid-caps:** Higher growth potential, higher risk\n• **Defensive:** Pharma, FMCG (during uncertain times)\n\n**Sectors to Explore:**\n• IT - Digital transformation plays\n• Banking - Credit growth theme\n• EV/Auto - Future mobility\n\nRemember, this is virtual trading for learning! Do your own research before real investments.";
    }
    
    if (lowerMessage.contains('tip') || lowerMessage.contains('strateg') || lowerMessage.contains('how to')) {
      return "🎯 **Trading Tips:**\n\n• Start with blue-chip stocks\n• Diversify across 5-7 sectors\n• Set stop-losses (typically 5-10%)\n• Don't invest money you can't afford to lose\n• Learn from every trade, win or lose!";
    }
    
    // Default response with context awareness
    if (!portfolioContext.contains('Holdings: None')) {
      return "I can see your portfolio! Ask me about:\n• Your current holdings\n• Portfolio analysis\n• Market trends\n• Stock recommendations\n• Trading strategies\n\nWhat would you like to know? 🤖";
    }
    
    return "I'm your AI trading assistant! I can help you:\n• Analyze your portfolio\n• Discuss market trends\n• Research stocks\n• Share trading tips\n\nWhat would you like to explore? 🤖";
  }
}



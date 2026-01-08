import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';

/// Chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({super.key});

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      content: "Hi! I'm your AI Trading Assistant powered by Gemini. 👋\n\n"
          "I can help you with:\n"
          "• Analyzing your portfolio\n"
          "• Stock recommendations\n"
          "• Market trends & insights\n"
          "• Trading strategies\n\n"
          "How can I help you today?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Get context data
    final holdings = ref.read(portfolioProvider);
    final wallet = ref.read(walletProvider);
    final livePrices = ref.read(livePricesProvider);

    try {
      // Build context for AI
      String context = _buildPortfolioContext(holdings, wallet, livePrices);
      
      // Get AI response
      final response = await _geminiService.chat(text, context);
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(content: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          content: "Sorry, I encountered an error. Please try again.\n\nError: ${e.toString()}",
          isUser: false,
        ));
      });
    }
    _scrollToBottom();
  }

  String _buildPortfolioContext(List holdings, wallet, Map<String, double> livePrices) {
    final buffer = StringBuffer();
    buffer.writeln("User's Portfolio Context:");
    buffer.writeln("- Available Cash: ₹${wallet.balance.toStringAsFixed(2)}");
    buffer.writeln("- Initial Balance: ₹${wallet.initialBalance.toStringAsFixed(2)}");
    
    if (holdings.isEmpty) {
      buffer.writeln("- Holdings: None");
    } else {
      buffer.writeln("- Holdings:");
      double totalValue = 0;
      for (final h in holdings) {
        final price = livePrices[h.stock.instrumentKey] ?? h.avgBuyPrice;
        final value = h.quantity * price;
        totalValue += value;
        final pnl = value - h.investedValue;
        buffer.writeln("  • ${h.stock.symbol}: ${h.quantity} shares @ ₹${price.toStringAsFixed(2)} "
            "(P&L: ${pnl >= 0 ? '+' : ''}₹${pnl.toStringAsFixed(2)})");
      }
      buffer.writeln("- Total Portfolio Value: ₹${(wallet.balance + totalValue).toStringAsFixed(2)}");
    }
    
    return buffer.toString();
  }

  void _handleQuickAction(String action) {
    _messageController.text = action;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.accentPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  _isTyping ? 'Typing...' : 'Powered by Gemini',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTyping ? AppTheme.profitGreen : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  content: "Chat cleared. How can I help you?",
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips at top (always visible, horizontal scroll)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              border: Border(
                bottom: BorderSide(color: AppTheme.cardElevated.withOpacity(0.5)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickChip('📊 Portfolio Review'),
                  const SizedBox(width: 8),
                  _buildQuickChip('📈 Market Sentiment'),
                  const SizedBox(width: 8),
                  _buildQuickChip('💡 Trading Tips'),
                  const SizedBox(width: 8),
                  _buildQuickChip('🔍 Stock Analysis'),
                ],
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(color: AppTheme.cardElevated),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.accentPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentPurple : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: AppTheme.accentPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withOpacity(0.3 + (0.4 * (1 - value))),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      backgroundColor: AppTheme.cardDark,
      side: BorderSide(color: AppTheme.accentPurple.withOpacity(0.3)),
      onPressed: () => _handleQuickAction(text),
    );
  }
}

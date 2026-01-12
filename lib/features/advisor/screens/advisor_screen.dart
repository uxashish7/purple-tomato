import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/providers/portfolio_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../core/providers/market_data_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';

/// Attachment type enum
enum AttachmentType { none, image, pdf, url }

/// Chat message model with attachment support
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final AttachmentType attachmentType;
  final Uint8List? imageBytes;
  final String? attachmentName;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
    this.attachmentType = AttachmentType.none,
    this.imageBytes,
    this.attachmentName,
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
  
  // Attachment state - store bytes directly (works on all platforms)
  Uint8List? _pendingImage;
  Uint8List? _pendingPdfBytes;  // Changed from path to bytes
  String? _pendingPdfName;
  final ImagePicker _imagePicker = ImagePicker();

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
          "📷 Attach images (charts, screenshots)\n"
          "📄 Upload PDFs (reports, statements)\n"
          "🔗 Paste URLs for article summary\n\n"
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
    if (text.isEmpty && _pendingImage == null && _pendingPdfBytes == null) return;

    // Capture pending attachments before clearing
    final imageBytes = _pendingImage;
    final pdfBytes = _pendingPdfBytes;
    final pdfName = _pendingPdfName;

    // Detect URL in message
    final urlRegex = RegExp(r'https?://[^\s]+');
    final urlMatch = urlRegex.firstMatch(text);
    String? urlContent;
    if (urlMatch != null) {
      urlContent = await _fetchUrlContent(urlMatch.group(0)!);
    }

    // Add user message with attachment info
    String displayText = text;
    if (imageBytes != null) displayText = '📷 [Image] $text';
    if (pdfName != null) displayText = '📄 [$pdfName] $text';
    
    setState(() {
      _messages.add(ChatMessage(
        content: displayText.isNotEmpty ? displayText : (imageBytes != null ? '📷 Analyze this image' : '📄 Analyze this PDF'),
        isUser: true,
        attachmentType: imageBytes != null ? AttachmentType.image : (pdfName != null ? AttachmentType.pdf : AttachmentType.none),
        imageBytes: imageBytes,
        attachmentName: pdfName,
      ));
      _isTyping = true;
      _pendingImage = null;
      _pendingPdfBytes = null;
      _pendingPdfName = null;
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
      
      // Add URL content to context if detected
      if (urlContent != null) {
        context += '\n\n[URL Content from ${urlMatch!.group(0)}]:\n$urlContent';
      }
      
      // Get AI response (with or without attachments)
      final response = await _geminiService.chatWithAttachments(
        text.isEmpty ? 'Analyze this' : text,
        context,
        imageBytes: imageBytes,
        pdfBytes: pdfBytes,  // Changed from pdfPath to pdfBytes
      );
      
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

  /// Pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pendingImage = bytes;
          _pendingPdfPath = null;
          _pendingPdfName = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📷 Image attached. Type a question about it.'),
            backgroundColor: AppTheme.accentPurple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.lossRed,
        ),
      );
    }
  }

  /// Pick a PDF file
  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF too large. Maximum size is 5MB.'),
              backgroundColor: AppTheme.lossRed,
            ),
          );
          return;
        }
        
        setState(() {
          _pendingPdfBytes = file.bytes;  // Use bytes directly
          _pendingPdfName = file.name;
          _pendingImage = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 PDF attached: ${file.name}'),
            backgroundColor: AppTheme.accentPurple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick PDF: $e'),
          backgroundColor: AppTheme.lossRed,
        ),
      );
    }
  }

  /// Clear pending attachment
  void _clearAttachment() {
    setState(() {
      _pendingImage = null;
      _pendingPdfBytes = null;
      _pendingPdfName = null;
    });
  }

  /// Detect URL in message and fetch content
  Future<String?> _fetchUrlContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        // Simple text extraction from HTML (basic)
        String body = response.body;
        // Remove scripts and styles
        body = body.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), '');
        body = body.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '');
        // Remove HTML tags
        body = body.replaceAll(RegExp(r'<[^>]+>'), ' ');
        // Clean up whitespace
        body = body.replaceAll(RegExp(r'\s+'), ' ').trim();
        // Limit to first 2000 chars
        if (body.length > 2000) body = body.substring(0, 2000) + '...';
        return body;
      }
    } catch (e) {
      print('URL fetch error: $e');
    }
    return null;
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
          
          // Message input with attachments
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(color: AppTheme.cardElevated),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pending attachment preview
                  if (_pendingImage != null || _pendingPdfName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pendingImage != null ? Icons.image : Icons.picture_as_pdf,
                            color: AppTheme.accentPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pendingImage != null ? 'Image attached' : _pendingPdfName ?? 'PDF attached',
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _clearAttachment,
                            child: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                          ),
                        ],
                      ),
                    ),
                  // Input row
                  Row(
                    children: [
                      // Image picker button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.image, color: AppTheme.textMuted, size: 20),
                          onPressed: _pickImage,
                          tooltip: 'Attach Image',
                        ),
                      ),
                      const SizedBox(width: 6),
                      // PDF picker button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.attach_file, color: AppTheme.textMuted, size: 20),
                          onPressed: _pickPdf,
                          tooltip: 'Attach PDF (max 5MB)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text input
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: _pendingImage != null 
                                  ? 'Ask about this image...'
                                  : (_pendingPdfName != null 
                                      ? 'Ask about this PDF...'
                                      : 'Ask anything or paste URL...'),
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
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

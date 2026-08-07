import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'package:purple_tomato/core/providers/upstox_auth_provider.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';
import '../../market/screens/home_screen.dart';

/// OAuth callback screen for WEB platform - handles Upstox redirect
class CallbackScreen extends ConsumerStatefulWidget {
  const CallbackScreen({super.key});

  @override
  ConsumerState<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends ConsumerState<CallbackScreen> {
  bool _isProcessing = true;
  String? _error;
  String? _code;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      final fullUrl = html.window.location.href;
      final fullUri = Uri.parse(fullUrl);
      
      String? code = fullUri.queryParameters['code'];
      String? error = fullUri.queryParameters['error'];

      // Fallback: check query parameters if attached after hash fragment (#/callback?code=xyz)
      if ((code == null || code.isEmpty) && fullUrl.contains('?')) {
        final queryPart = fullUrl.substring(fullUrl.indexOf('?'));
        final dummyUri = Uri.parse('http://localhost$queryPart');
        code ??= dummyUri.queryParameters['code'];
        error ??= dummyUri.queryParameters['error'];
      }
      
      if (error != null) {
        setState(() {
          _error = 'Authentication failed: $error';
          _isProcessing = false;
        });
        return;
      }
      
      if (code == null || code.isEmpty) {
        setState(() {
          _error = 'No authorization code received';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _code = code;
      });

      // Exchange the code for access token
      final success = await ref
          .read(upstoxAuthProvider.notifier)
          .handleAuthCallback(code);

      if (success) {
        // Wait a moment for user to see success message
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        setState(() {
          _error = 'Failed to exchange authorization code';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing callback: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                // Processing animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPurple,
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connecting to Upstox...',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we complete authentication',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_code != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.profitGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authorization code received',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (_error != null) ...[
                // Error state
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.lossRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppTheme.lossRed,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Authentication Failed',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

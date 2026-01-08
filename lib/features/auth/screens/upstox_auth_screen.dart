import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/upstox_auth_provider.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';

class UpstoxAuthScreen extends ConsumerStatefulWidget {
  const UpstoxAuthScreen({super.key});

  @override
  ConsumerState<UpstoxAuthScreen> createState() => _UpstoxAuthScreenState();
}

class _UpstoxAuthScreenState extends ConsumerState<UpstoxAuthScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(upstoxAuthProvider);
    final isAuthenticated = authState == UpstoxAuthState.authenticated;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Connect Upstox'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? AppTheme.profitGreen.withOpacity(0.1)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAuthenticated
                      ? AppTheme.profitGreen.withOpacity(0.3)
                      : AppTheme.cardElevated,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isAuthenticated
                          ? AppTheme.profitGreen.withOpacity(0.2)
                          : AppTheme.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAuthenticated ? Icons.check_circle : Icons.link_off,
                      color: isAuthenticated
                          ? AppTheme.profitGreen
                          : AppTheme.textMuted,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthenticated ? 'Connected to Upstox' : 'Not Connected',
                    style: TextStyle(
                      color: isAuthenticated
                          ? AppTheme.profitGreen
                          : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAuthenticated
                        ? 'Live market data is enabled'
                        : 'Connect to get live market data',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (!isAuthenticated) ...[
              // Instructions
              const Text(
                'How to Connect',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildStep(
                1,
                'Configure API',
                'Add your Upstox API credentials in api_config.dart',
                ApiConfig.isUpstoxConfigured,
              ),
              _buildStep(
                2,
                'Login to Upstox',
                'Click the button below to open Upstox login',
                false,
              ),
              _buildStep(
                3,
                'Copy Authorization Code',
                'After login, copy the code from the redirect URL',
                false,
              ),
              _buildStep(
                4,
                'Paste Code Below',
                'Enter the code to complete authentication',
                false,
              ),
              
              const SizedBox(height: 24),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ApiConfig.isUpstoxConfigured
                      ? _launchUpstoxLogin
                      : null,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open Upstox Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              if (!ApiConfig.isUpstoxConfigured) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningOrange.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'API not configured. Update api_config.dart with your Upstox credentials.',
                          style: TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Code Input
              const Text(
                'Authorization Code',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'Paste code from redirect URL...',
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _codeController.text.isNotEmpty && !_isLoading
                      ? _handleAuthCallback
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Connect'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Skip option
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(upstoxAuthProvider.notifier).skipAuth();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Using app with simulated data'),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
            ] else ...[
              // Disconnect button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(upstoxAuthProvider.notifier).logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Disconnected from Upstox'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lossRed,
                    side: const BorderSide(color: AppTheme.lossRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: completed
                  ? AppTheme.profitGreen
                  : AppTheme.cardElevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.black, size: 16)
                  : Text(
                      '$number',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpstoxLogin() async {
    final authUrl = ref.read(upstoxAuthProvider.notifier).getAuthorizationUrl();
    final uri = Uri.parse(authUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch browser'),
          backgroundColor: AppTheme.lossRed,
        ),
      );
    }
  }

  Future<void> _handleAuthCallback() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(upstoxAuthProvider.notifier)
          .handleAuthCallback(_codeController.text.trim());

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Upstox!'),
            backgroundColor: AppTheme.profitGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to authenticate. Check the code and try again.'),
            backgroundColor: AppTheme.lossRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

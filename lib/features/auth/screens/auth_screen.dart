import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/providers/upstox_auth_provider.dart';
import '../../market/screens/home_screen.dart';
import 'upstox_auth_screen.dart';
// Conditional import: web uses dart:html redirect, mobile uses stub
import 'auth_redirect_stub.dart'
    if (dart.library.html) 'auth_redirect_web.dart';


/// Authentication screen with Upstox OAuth and Guest mode
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  /// Handle Upstox login with platform-specific behavior
  Future<void> _handleUpstoxLogin(BuildContext context, WidgetRef ref) async {
    final authUrl = ref.read(upstoxAuthProvider.notifier).getAuthorizationUrl();
    
    if (kIsWeb) {
      // WEB: Redirect same tab to Upstox (automatic flow)
      redirectToUpstox(authUrl);
    } else {
      // MOBILE: Navigate to manual code entry screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpstoxAuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // App Icon/Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentPurple,
                      AppTheme.accentPurple.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                'Purple Tomato',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              
             const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Virtual Stock Trading',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Features list
              _buildFeatureItem(Icons.show_chart, 'All 5000+ NSE/BSE stocks'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.account_balance_wallet, 'Virtual ₹10 Lakh to trade'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.psychology, 'AI-powered trading advisor'),
              const SizedBox(height: 12),
              _buildFeatureItem(Icons.speed, 'Real-time live data streaming'),
              
              const Spacer(flex: 2),
              
              // Upstox Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleUpstoxLogin(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Connect with Upstox',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Divider with "OR"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppTheme.borderSubtle,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppTheme.borderSubtle,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Guest Mode Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                      color: AppTheme.borderDefault,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Guest mode info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoDefault.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.infoDefault.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoDefault,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guest mode uses Yahoo Finance (popular stocks only)',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SafeArea(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

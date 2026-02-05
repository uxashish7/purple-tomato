import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'shared/theme/app_theme.dart';
import 'features/market/screens/home_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/callback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive (local storage)
  await Hive.initFlutter();
  await HiveService.init();
  
  // Initialize Supabase (cloud database + auth)
  await SupabaseService.initialize();
  
  runApp(
    const ProviderScope(
      child: VirtualTradingApp(),
    ),
  );
}

class VirtualTradingApp extends StatelessWidget {
  const VirtualTradingApp({super.key});

  // Determine initial route based on URL (for web OAuth callback)
  Widget _getInitialScreen() {
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      // Check if this is an OAuth callback
      if (uri.path.contains('/callback')) {
        return const CallbackScreen();
      }
    }
    // Default to auth screen
    return const AuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purple Tomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Use route-aware initial screen
      home: _getInitialScreen(),
      // Define named routes for navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/callback': (context) => const CallbackScreen(),
      },
    );
  }
}

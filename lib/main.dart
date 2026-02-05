import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'shared/theme/app_theme.dart';
import 'features/market/screens/home_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/callback_screen.dart';
import 'core/providers/upstox_auth_provider.dart';
// Conditional import for URL checking
import 'core/utils/url_helper_stub.dart'
    if (dart.library.html) 'core/utils/url_helper_web.dart';

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

class VirtualTradingApp extends ConsumerWidget {
  const VirtualTradingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this is a callback route on web
    final bool isCallback = kIsWeb && isCallbackRoute();
    
    return MaterialApp(
      title: 'Purple Tomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Use CallbackScreen if on callback route, else AuthWrapper
      home: isCallback ? const CallbackScreen() : const AuthWrapper(),
      // Define named routes for navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/callback': (context) => const CallbackScreen(),
      },
    );
  }
}

/// Wrapper that checks auth status and routes accordingly
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(upstoxAuthProvider);
    
    // If authenticated, go straight to HomeScreen
    if (authState == UpstoxAuthState.authenticated) {
      return const HomeScreen();
    }
    
    // Otherwise, show AuthScreen
    return const AuthScreen();
  }
}

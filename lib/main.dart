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
    return MaterialApp(
      title: 'Purple Tomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Use AuthWrapper to check auth status
      home: const AuthWrapper(),
      // Define named routes for navigation
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/callback': (context) => const CallbackScreen(),
      },
      // Handle initial route from URL (for web deep links)
      onGenerateInitialRoutes: (String initialRouteName) {
        // For web, check if URL contains /callback
        if (kIsWeb && initialRouteName.contains('/callback')) {
          return [
            MaterialPageRoute(builder: (_) => const CallbackScreen()),
          ];
        }
        // Default to auth wrapper
        return [
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        ];
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

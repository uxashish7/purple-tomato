import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'shared/theme/app_theme.dart';
import 'features/market/screens/home_screen.dart';
import 'features/auth/screens/auth_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purple Tomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Upstox authentication enabled
      // Users will login with Upstox OAuth before accessing the app
      home: const AuthScreen(),
    );
  }
}

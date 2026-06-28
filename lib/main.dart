import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, PlatformDispatcher;
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/app_logger.dart';
import 'shared/theme/app_theme.dart';
import 'core/router/app_router.dart';
// Conditional import for URL checking
import 'core/utils/url_helper_stub.dart'
    if (dart.library.html) 'core/utils/url_helper_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global error handlers ──────────────────────────────────────────────
  // Catches Flutter framework errors (e.g., build/paint exceptions).
  FlutterError.onError = (details) {
    AppLogger.error(
      'Uncaught Flutter error: ${details.exceptionAsString()}',
      tag: 'App',
    );
    FlutterError.presentError(details); // still shows red screen in debug
  };

  // Catches async Dart errors not caught by the framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught async error', tag: 'App', error: error, stackTrace: stack);
    return true; // Mark as handled so the app doesn't crash
  };
  // ── End global error handlers ──────────────────────────────────────────

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
    final goRouter = ref.watch(goRouterProvider);
    
    return MaterialApp.router(
      title: 'Purple Tomato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
    );
  }
}

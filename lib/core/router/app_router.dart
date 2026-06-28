import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/callback_screen.dart';
import '../../features/auth/screens/upstox_auth_screen.dart';
import '../../features/market/screens/home_screen.dart';
import '../../features/market/screens/stock_detail_screen.dart';
import '../../features/market/screens/stock_search_screen.dart';
import '../constants/route_names.dart';
import '../models/stock.dart';
import '../providers/upstox_auth_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(upstoxAuthProvider);
  final isGuestMode = ref.watch(isGuestModeProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState == UpstoxAuthState.authenticated || isGuestMode;
      final isAuthScreen = state.uri.path == '/auth';
      final isCallbackScreen = state.uri.path.startsWith('/callback');

      // Allow callback to process regardless of current auth state
      if (isCallbackScreen) return null;

      // If not authenticated and not already on auth screen, redirect to auth
      if (!isAuth && !isAuthScreen) return '/auth';
      
      // If authenticated and trying to access auth screen, redirect to home
      if (isAuth && isAuthScreen) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/callback',
        name: RouteNames.callback,
        builder: (context, state) => const CallbackScreen(),
      ),
      GoRoute(
        path: '/stock',
        name: RouteNames.stockDetail,
        builder: (context, state) {
          final stock = state.extra as Stock;
          return StockDetailScreen(stock: stock);
        },
      ),
      GoRoute(
        path: '/search',
        name: RouteNames.stockSearch,
        builder: (context, state) => const StockSearchScreen(),
      ),
      GoRoute(
        path: '/upstox-auth',
        name: RouteNames.upstoxAuth,
        builder: (context, state) => const UpstoxAuthScreen(),
      ),
    ],
  );
});

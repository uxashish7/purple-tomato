import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:purple_tomato/features/auth/screens/auth_screen.dart';
import 'package:purple_tomato/features/auth/screens/callback_screen.dart';
import 'package:purple_tomato/features/auth/screens/upstox_auth_screen.dart';
import 'package:purple_tomato/features/market/screens/home_screen.dart';
import 'package:purple_tomato/features/market/screens/stock_detail_screen.dart';
import 'package:purple_tomato/features/market/screens/stock_search_screen.dart';
import '../constants/route_names.dart';
import 'package:purple_tomato/domain/models/stock.dart';
import '../providers/upstox_auth_provider.dart';

/// Notifier to refresh GoRouter without re-creating the GoRouter instance
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<UpstoxAuthState>(
      upstoxAuthProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<bool>(
      isGuestModeProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);
  
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(upstoxAuthProvider);
      final isGuestMode = ref.read(isGuestModeProvider);

      final isAuth = authState == UpstoxAuthState.authenticated || isGuestMode;
      final isAuthScreen = state.uri.path == '/auth';
      final isCallbackScreen = state.uri.path.startsWith('/callback');

      // Allow callback to process regardless of current auth state.
      // If user is authenticated while on callback, redirect to home.
      if (isCallbackScreen) {
        if (isAuth) return '/';
        return null;
      }

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
        path: '/stock/:symbol',
        name: RouteNames.stockDetail,
        builder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? 'RELIANCE';
          final stock = (state.extra as Stock?) ??
              Stock(
                instrumentKey: 'NSE_EQ|$symbol',
                symbol: symbol,
                name: symbol,
                exchange: 'NSE',
                instrumentType: 'EQUITY',
              );
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

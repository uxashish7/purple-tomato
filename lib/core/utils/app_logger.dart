import 'package:flutter/foundation.dart';

/// Structured application logger.
///
/// • In **debug/profile** builds: outputs messages via [debugPrint] (visible
///   in the IDE console and filtered by log level tag).
/// • In **release** builds: all calls are compiled away to no-ops so no
///   sensitive data leaks into production logs.
///
/// Usage:
/// ```dart
/// AppLogger.info('Market data refreshed', tag: 'MarketDataProvider');
/// AppLogger.warn('Falling back to mock quotes', tag: 'UpstoxService');
/// AppLogger.error('Token exchange failed', tag: 'UpstoxService', error: e);
/// ```
///
/// SECURITY RULES:
/// • Never pass access tokens, auth codes, or raw API responses to any logger.
/// • Redact PII (user IDs, emails) before logging.
class AppLogger {
  AppLogger._(); // prevent instantiation

  // ── Log levels ──────────────────────────────────────────────────────────────

  /// Informational log — general lifecycle events.
  static void info(String message, {String? tag}) {
    _log('ℹ', tag, message);
  }

  /// Warning log — recoverable issues or unexpected-but-handled states.
  static void warn(String message, {String? tag, dynamic error}) {
    _log('⚠', tag, message);
  }

  /// Error log — failures that affect functionality.
  /// [error] is the caught exception; [stackTrace] is optional.
  /// Only the **type** of the error is logged by default to avoid leaking
  /// sensitive data that might be present in exception messages.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final errorType = error != null ? ' [${error.runtimeType}]' : '';
    _log('❌', tag, '$message$errorType');
    if (stackTrace != null && kDebugMode) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }

  /// Debug-only log — verbose details only needed during development.
  /// Automatically stripped in profile/release builds.
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('🔍', tag, message);
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  static void _log(String level, String? tag, String message) {
    if (!kReleaseMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$level $prefix$message');
    }
  }
}

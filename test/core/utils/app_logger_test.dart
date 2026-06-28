import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/core/utils/app_logger.dart';

/// Unit tests for AppLogger.
/// Verifies that all public methods are callable without throwing.
void main() {
  group('AppLogger', () {
    test('info() does not throw', () {
      expect(() => AppLogger.info('test message', tag: 'Test'), returnsNormally);
    });

    test('warn() does not throw', () {
      expect(() => AppLogger.warn('test warning', tag: 'Test'), returnsNormally);
    });

    test('error() does not throw with no error object', () {
      expect(() => AppLogger.error('test error', tag: 'Test'), returnsNormally);
    });

    test('error() does not throw with error object', () {
      expect(
        () => AppLogger.error(
          'test error with object',
          tag: 'Test',
          error: Exception('something went wrong'),
        ),
        returnsNormally,
      );
    });

    test('debug() does not throw', () {
      expect(() => AppLogger.debug('debug message', tag: 'Test'), returnsNormally);
    });

    test('info() works without a tag', () {
      expect(() => AppLogger.info('no tag message'), returnsNormally);
    });
  });
}

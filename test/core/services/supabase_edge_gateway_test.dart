import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/core/services/supabase_service.dart';

void main() {
  group('SupabaseService Edge Gateway Tests', () {
    test('exchangeUpstoxCodeViaEdgeGateway returns null gracefully when Supabase client is uninitialized', () async {
      final result = await SupabaseService.exchangeUpstoxCodeViaEdgeGateway(
        code: 'test_code_123',
        redirectUri: 'http://localhost:8000/callback',
      );

      expect(result, isNull);
    });
  });
}

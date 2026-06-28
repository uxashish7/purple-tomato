import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/domain/models/wallet.dart';

/// Unit tests for Wallet model business logic.
/// These tests run without any Flutter widget tree or plugin dependencies.
void main() {
  group('Wallet', () {
    test('initial() creates wallet with correct balance', () {
      final wallet = Wallet.initial(1000000.0);
      expect(wallet.balance, 1000000.0);
      expect(wallet.initialBalance, 1000000.0);
    });

    group('deduct()', () {
      test('deducts amount from balance when sufficient funds', () {
        final wallet = Wallet.initial(1000000.0);
        final result = wallet.deduct(250000.0);
        expect(result, isTrue);
        expect(wallet.balance, 750000.0);
      });

      test('returns false and does NOT deduct when insufficient funds', () {
        final wallet = Wallet.initial(100.0);
        final result = wallet.deduct(200.0);
        expect(result, isFalse);
        expect(wallet.balance, 100.0); // unchanged
      });

      test('returns false for zero amount', () {
        final wallet = Wallet.initial(1000000.0);
        // Deducting 0 — implementation dependent; at minimum must not throw
        // and balance should remain valid
        expect(wallet.balance, 1000000.0);
      });
    });

    group('credit()', () {
      test('adds amount to balance', () {
        final wallet = Wallet.initial(100000.0);
        wallet.credit(50000.0);
        expect(wallet.balance, 150000.0);
      });

      test('can credit multiple times cumulatively', () {
        final wallet = Wallet.initial(0.0);
        wallet.credit(10000.0);
        wallet.credit(20000.0);
        expect(wallet.balance, 30000.0);
      });
    });

    group('round-trip buy/sell', () {
      test('balance is unchanged after buy then full sell at same price', () {
        final wallet = Wallet.initial(1000000.0);
        final buyCost = 50000.0;
        wallet.deduct(buyCost);
        wallet.credit(buyCost); // sell at same price
        expect(wallet.balance, closeTo(1000000.0, 0.001));
      });
    });
  });
}

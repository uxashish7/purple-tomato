import 'package:flutter_test/flutter_test.dart';
import 'package:purple_tomato/domain/models/order.dart';
import 'package:purple_tomato/domain/models/stock.dart';

void main() {
  group('Advanced Order Engine Models & Logic Tests', () {
    final testStock = Stock(
      instrumentKey: 'NSE_EQ|INE002A01018',
      symbol: 'RELIANCE',
      name: 'Reliance Industries Ltd',
      exchange: 'NSE',
      instrumentType: 'EQUITY',
    );

    test('Limit Buy Order creation properties', () {
      final order = Order.limitBuy(
        id: 'order-1',
        stock: testStock,
        quantity: 10,
        targetPrice: 2800.0,
      );

      expect(order.isBuy, isTrue);
      expect(order.isLimit, isTrue);
      expect(order.isPending, isTrue);
      expect(order.targetPrice, equals(2800.0));
      expect(order.totalValue, equals(28000.0));
    });

    test('Stop-Loss Order creation properties', () {
      final order = Order.stopLoss(
        id: 'order-2',
        stock: testStock,
        quantity: 5,
        triggerPrice: 2700.0,
      );

      expect(order.isSell, isTrue);
      expect(order.isStopLoss, isTrue);
      expect(order.isPending, isTrue);
      expect(order.triggerPrice, equals(2700.0));
      expect(order.totalValue, equals(13500.0));
    });

    test('Order copyWith status update converts pending to executed', () {
      final pendingOrder = Order.limitBuy(
        id: 'order-3',
        stock: testStock,
        quantity: 2,
        targetPrice: 2500.0,
      );

      final executedOrder = pendingOrder.copyWith(statusIndex: 0, price: 2490.0);

      expect(executedOrder.isPending, isFalse);
      expect(executedOrder.isExecuted, isTrue);
      expect(executedOrder.price, equals(2490.0));
    });
  });
}

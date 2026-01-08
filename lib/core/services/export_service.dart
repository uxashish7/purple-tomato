import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'hive_service.dart';

/// Service for exporting transaction data to CSV
class ExportService {
  /// Export all transactions to CSV and share
  static Future<void> exportTransactionsToCSV() async {
    final orders = HiveService.getOrders();
    
    if (orders.isEmpty) {
      throw Exception('No transactions to export');
    }
    
    final csv = _generateCSV(orders);
    final fileName = 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    
    await Share.share(
      csv,
      subject: 'Virtual Trading Transactions Export - $fileName',
    );
  }
  
  /// Generate CSV content from orders
  static String _generateCSV(List<Order> orders) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Date,Time,Type,Symbol,Stock Name,Quantity,Price,Total Value,Brokerage');
    
    // CSV Data rows
    for (final order in orders) {
      final date = DateFormat('dd/MM/yyyy').format(order.timestamp);
      final time = DateFormat('HH:mm:ss').format(order.timestamp);
      final type = order.orderType == OrderType.buy ? 'BUY' : 'SELL';
      final symbol = order.stock.symbol;
      final name = order.stock.name.replaceAll(',', ' '); // Escape commas
      final quantity = order.quantity;
      final price = order.price.toStringAsFixed(2);
      final totalValue = order.totalValue.toStringAsFixed(2);
      final brokerage = (order.totalValue * 0.001).toStringAsFixed(2);
      
      buffer.writeln('$date,$time,$type,$symbol,$name,$quantity,$price,$totalValue,$brokerage');
    }
    
    return buffer.toString();
  }
  
  /// Get transaction summary text
  static String getTransactionSummary() {
    final orders = HiveService.getOrders();
    final buyCount = orders.where((o) => o.orderType == OrderType.buy).length;
    final sellCount = orders.where((o) => o.orderType == OrderType.sell).length;
    final totalBuyValue = orders
        .where((o) => o.orderType == OrderType.buy)
        .fold(0.0, (sum, o) => sum + o.totalValue);
    final totalSellValue = orders
        .where((o) => o.orderType == OrderType.sell)
        .fold(0.0, (sum, o) => sum + o.totalValue);
    
    return '''
Virtual Trading Summary
=======================
Total Transactions: ${orders.length}
Buy Orders: $buyCount (₹${totalBuyValue.toStringAsFixed(2)})
Sell Orders: $sellCount (₹${totalSellValue.toStringAsFixed(2)})
''';
  }
}

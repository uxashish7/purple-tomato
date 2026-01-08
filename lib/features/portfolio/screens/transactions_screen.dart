import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/models/order.dart';
import '../../../shared/theme/app_theme.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filter = 'All';

  String _generateShareText() {
    final holdings = HiveService.getHoldings();
    final wallet = HiveService.getWallet();
    
    if (holdings.isEmpty) {
      return '📊 Virtual Trading Portfolio\n\n'
             '💰 Balance: ₹${(wallet?.balance ?? 0).toStringAsFixed(0)}\n'
             '📈 No holdings yet!\n\n'
             'Start your trading journey today! 🚀';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('📊 My Virtual Trading Portfolio\n');
    buffer.writeln('🏦 Holdings:');
    
    for (final holding in holdings.take(5)) {
      buffer.writeln('• ${holding.stock.symbol} - ${holding.quantity} shares');
    }
    
    if (holdings.length > 5) {
      buffer.writeln('   ...and ${holdings.length - 5} more');
    }
    
    buffer.writeln('\n💰 Cash: ₹${(wallet?.balance ?? 0).toStringAsFixed(0)}');
    buffer.writeln('\n#VirtualTrading #StockMarket #Investment');
    
    return buffer.toString();
  }

  Future<void> _exportToPDF() async {
    final orders = HiveService.getOrders();
    final wallet = HiveService.getWallet();
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Virtual Trading - Transaction Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Orders', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('${orders.length}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Buys', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('${orders.where((o) => o.isBuy).length}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Sells', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('${orders.where((o) => o.isSell).length}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Balance', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('₹${(wallet?.balance ?? 0).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Transactions Table
            pw.Text(
              'Transaction History',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            if (orders.isEmpty)
              pw.Text('No transactions yet')
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                headers: ['Stock', 'Type', 'Qty', 'Price', 'Total'],
                data: orders.map((order) => [
                  order.stock.symbol,
                  order.isBuy ? 'BUY' : 'SELL',
                  order.quantity.toString(),
                  '₹${order.price.toStringAsFixed(2)}',
                  '₹${order.totalValue.toStringAsFixed(2)}',
                ]).toList(),
              ),
          ];
        },
      ),
    );
    
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'virtual_trading_report.pdf');
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share & Export',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Share to Social Media
            _ShareListTile(
              icon: Icons.share,
              iconColor: AppTheme.accentBlue,
              title: 'Share Portfolio',
              subtitle: 'Share to WhatsApp, Instagram, X & more',
              onTap: () {
                Navigator.pop(context);
                Share.share(_generateShareText());
              },
            ),
            const SizedBox(height: 12),
            
            // Export PDF
            _ShareListTile(
              icon: Icons.picture_as_pdf,
              iconColor: AppTheme.lossRed,
              title: 'Export as PDF',
              subtitle: 'Download transaction report',
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = HiveService.getOrders();
    
    // Filter orders - use isBuy/isSell getters for correct comparison
    List<Order> filteredOrders;
    if (_filter == 'Buys') {
      filteredOrders = allOrders.where((o) => o.isBuy).toList();
    } else if (_filter == 'Sells') {
      filteredOrders = allOrders.where((o) => o.isSell).toList();
    } else {
      filteredOrders = allOrders;
    }

    final buyCount = allOrders.where((o) => o.isBuy).length;
    final sellCount = allOrders.where((o) => o.isSell).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.lossRed),
            tooltip: 'Download PDF',
            onPressed: _exportToPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long,
                    label: 'Total',
                    value: allOrders.length.toString(),
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.arrow_downward,
                    label: 'Buys',
                    value: buyCount.toString(),
                    color: AppTheme.profitGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.arrow_upward,
                    label: 'Sells',
                    value: sellCount.toString(),
                    color: AppTheme.lossRed,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Buys', 'Sells'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                    backgroundColor: AppTheme.cardDark,
                    selectedColor: AppTheme.accentBlue.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accentBlue : AppTheme.cardElevated,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Orders List
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.textMuted,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_filter.toLowerCase()} yet',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start trading to see your history',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _OrderCard(order: order);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardElevated,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, hh:mm a').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = order.isBuy;  // Use proper getter
    final color = isBuy ? AppTheme.profitGreen : AppTheme.lossRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardElevated,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Order type indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Stock info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.stock.symbol,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Removed confusing B/S badge - icon already indicates type
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.timestamp),
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isBuy ? '-' : '+'}${_formatCurrency(order.totalValue)}',
                    style: TextStyle(
                      color: isBuy ? AppTheme.lossRed : AppTheme.profitGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${order.quantity} × ${_formatCurrency(order.price)}',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.cardElevated, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Brokerage',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '₹${(order.totalValue * 0.001).toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
/// Share list tile for the share bottom sheet
class _ShareListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDefault,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

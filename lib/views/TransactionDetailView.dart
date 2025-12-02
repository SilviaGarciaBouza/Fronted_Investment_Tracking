import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:intl/intl.dart';

class TransactionDetailView extends StatelessWidget {
  final Item item;
  const TransactionDetailView({super.key, required this.item});

  static const Color primaryDark = Colors.black;
  static const Color accentGreen = Colors.lightGreenAccent;
  static const Color textColor = Colors.white;

  Color _getPnlColor(double nRpL) {
    if (nRpL > 0) {
      return accentGreen;
    } else if (nRpL < 0) {
      return Colors.redAccent;
    } else {
      return textColor.withOpacity(0.8);
    }
  }

  List<Widget> _buildTransactionList(double marketValuePerShare) {
    List<Widget> transactionWidgets = [];

    for (var tx in item.transactions) {
      final txValueEur = tx.stocks * marketValuePerShare;
      final txPnL = txValueEur - tx.invEur;

      transactionWidgets.add(
        Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              '${DateFormat('dd/MM/yy').format(tx.date)} - Compra',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Unidades: ${tx.stocks.toStringAsFixed(2)} | Precio Compra: ${tx.purchasePrice.toStringAsFixed(3)}€',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'P&L: ${txPnL.toStringAsFixed(2)}€',
                  style: TextStyle(
                    color: _getPnlColor(txPnL),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Inv: ${tx.invEur.toStringAsFixed(2)}€',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return transactionWidgets;
  }

  @override
  Widget build(BuildContext context) {
    final marketValuePerShare = item.valueEur / item.stocks;

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: accentGreen,
        title: Text(
          '${item.name} - Transacciones',
          style: const TextStyle(color: accentGreen),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio de Mercado Actual: ${marketValuePerShare.toStringAsFixed(3)}€',
                    style: const TextStyle(color: textColor, fontSize: 16),
                  ),
                  Text(
                    'Coste Promedio Ponderado (WAC): ${item.sharePrize.toStringAsFixed(3)}€',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Historial de Compras:',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          ..._buildTransactionList(marketValuePerShare),
        ],
      ),
    );
  }
}

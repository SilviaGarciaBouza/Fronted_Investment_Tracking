import 'package:flutter/material.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:intl/intl.dart';

/// Desglose de todas las compras realizadas de un activo.
class TransactionDetailView extends StatelessWidget {
  final Item item;
  const TransactionDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: item.transactions.length,
              itemBuilder: (context, index) {
                final tx = item.transactions[index];
                final txPnL = (tx.stocks * item.currentPrice) - tx.invEur;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      DateFormat('dd/MM/yyyy').format(tx.purchaseDate),
                    ),
                    subtitle: Text("${tx.stocks} x ${tx.purchasePrice}€"),
                    trailing: Text(
                      "${txPnL.toStringAsFixed(2)}€",
                      style: TextStyle(
                        color: txPnL >= 0
                            ? Colors.lightGreenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _column(
            "Media",
            "${(item.totalInvEur / item.totalStocks).toStringAsFixed(2)}€",
          ),
          _column("Actual", "${item.currentPrice}€"),
        ],
      ),
    );
  }

  Widget _column(String label, String value) => Column(
    children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

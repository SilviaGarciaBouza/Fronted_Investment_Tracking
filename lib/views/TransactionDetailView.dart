import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../viewmodels/InvViewModel.dart';
import '../utils/app_strings.dart';

class TransactionDetailView extends StatelessWidget {
  final Item item;
  const TransactionDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.get('back_tooltip', lang),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: primary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: vm.isDarkMode ? Colors.white10 : Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _col(
                  AppStrings.get('avg', lang),
                  "${item.totalStocks == 0 ? '0.00' : (item.totalInvEur / item.totalStocks).toStringAsFixed(2)}€",
                ),
                _col(AppStrings.get('current', lang), "${item.currentPrice}€"),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: item.transactions.length,
              itemBuilder: (context, index) {
                final tx = item.transactions[index];
                final txPnL = (tx.stocks * item.currentPrice) - tx.invEur;
                return Card(
                  color: vm.isDarkMode ? Colors.grey.shade900 : Colors.white,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      DateFormat('dd/MM/yyyy').format(tx.purchaseDate),
                      style: TextStyle(
                        color: vm.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      "${tx.stocks} x ${tx.purchasePrice}€",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      "${txPnL.toStringAsFixed(2)}€",
                      style: TextStyle(
                        color: txPnL >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
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

  Widget _col(String label, String val) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(
        val,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ],
  );
}

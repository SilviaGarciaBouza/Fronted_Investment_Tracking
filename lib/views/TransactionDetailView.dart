import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../viewmodels/InvViewModel.dart';
import '../utils/app_strings.dart';
import '../theme/app_theme.dart';

class TransactionDetailView extends StatelessWidget {
  final Item item;
  const TransactionDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final cs = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;

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
            color: cs.onSurface.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _col(
                  AppStrings.get('avg', lang),
                  "${item.totalStocks == 0 ? '0.00' : (item.totalInvEur / item.totalStocks).toStringAsFixed(2)}€",
                  cs.onSurfaceVariant,
                  cs.onSurface,
                ),
                _col(
                  AppStrings.get('current', lang),
                  "${item.currentPrice}€",
                  cs.onSurfaceVariant,
                  cs.onSurface,
                ),
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
                  color: cs.surface,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      DateFormat('dd/MM/yyyy').format(tx.purchaseDate),
                      style: TextStyle(color: cs.onSurface),
                    ),
                    subtitle: Text(
                      "${tx.stocks} x ${tx.purchasePrice}€",
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    trailing: Text(
                      "${txPnL.toStringAsFixed(2)}€",
                      style: TextStyle(
                        color: txPnL >= 0
                            ? appColors.pnlPositive
                            : appColors.pnlNegative,
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

  Widget _col(String label, String val, Color labelColor, Color valColor) =>
      Column(
        children: [
          Text(label, style: TextStyle(color: labelColor)),
          Text(
            val,
            style: TextStyle(
              color: valColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      );
}

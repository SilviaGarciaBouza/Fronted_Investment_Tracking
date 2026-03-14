import 'package:flutter/material.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:intl/intl.dart';

class TransactionDetailView extends StatelessWidget {
  final Item item;
  const TransactionDetailView({super.key, required this.item});

  // Configuración de colores (Sin azul)
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
      // Calculamos el P&L individual de esta compra
      final txValueEur = tx.stocks * marketValuePerShare;
      final txPnL = txValueEur - tx.invEur;

      transactionWidgets.add(
        Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: accentGreen.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              // Cambio de 'date' a 'purchaseDate' para coincidir con el DTO
              '${DateFormat('dd/MM/yy').format(tx.purchaseDate)} - Compra',
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Cant: ${tx.stocks.toStringAsFixed(2)} | Precio: ${tx.purchasePrice.toStringAsFixed(3)}€',
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
                  'Invertido: ${tx.invEur.toStringAsFixed(2)}€',
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
    // Evitamos división por cero si no hay stocks
    final marketValuePerShare = item.stocks > 0
        ? (item.valueEur / item.stocks)
        : 0.0;

    // Calculamos el precio medio de compra (WAC)
    final wac = item.stocks > 0 ? (item.invEur / item.stocks) : 0.0;

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        foregroundColor: accentGreen,
        title: Text(
          item.name.toUpperCase(),
          style: const TextStyle(
            color: accentGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de resumen de precio
          Card(
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              // border: Border.all(color: accentGreen.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTADO ACTUAL',
                    style: TextStyle(
                      color: accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Precio de Mercado: ${marketValuePerShare.toStringAsFixed(3)}€',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Precio Medio (WAC): ${wac.toStringAsFixed(3)}€',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Text(
              'HISTORIAL DE COMPRAS',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Lista de transacciones mapeada
          ..._buildTransactionList(marketValuePerShare),
        ],
      ),
    );
  }
}

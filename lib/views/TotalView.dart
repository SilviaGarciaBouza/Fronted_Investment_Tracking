import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/widgets/buildSummaryRow.dart'; // Importa el widget de la fila

class TotalView extends StatelessWidget {
  const TotalView({super.key});
  static const routeName = '/totalview';

  @override
  Widget build(BuildContext context) {
    final invViewmodel = Provider.of<Invviewmodel>(context);

    const Color primaryDark = Colors.black;
    const Color accentGreen = Colors.lightGreenAccent;
    const Color textColor = Colors.white;

    Color getNplColor(double nRPlPercentaje) {
      if (nRPlPercentaje > 0) {
        return accentGreen;
      } else if (nRPlPercentaje < 0) {
        return Colors.redAccent;
      } else {
        return textColor.withOpacity(0.8);
      }
    }

    Color totalPnLColor = getNplColor(invViewmodel.totalPnL);

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: accentGreen,
        title: const Text(
          "Resumen de Cartera",
          style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: accentGreen.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Rendimiento Total",
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                buildSummaryRow(
                  "Valor Actual:",
                  '${invViewmodel.totalCurrentValue.toStringAsFixed(2)}€',
                  textColor,
                ),
                buildSummaryRow(
                  "Inversión Inicial:",
                  '${invViewmodel.totalInvestment.toStringAsFixed(2)}€',
                  Colors.grey.shade400,
                ),
                const Divider(color: Colors.grey, height: 25),
                buildSummaryRow(
                  "Pérdida/Ganancia (P&L):",
                  '${invViewmodel.totalPnL.toStringAsFixed(2)}€',
                  totalPnLColor,
                  fontWeight: FontWeight.bold,
                ),
                buildSummaryRow(
                  "P&L %:",
                  '${invViewmodel.totalPnLPercent.toStringAsFixed(2)}%',
                  totalPnLColor,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';

class TotalView extends StatelessWidget {
  const TotalView({super.key});
  static const routeName = '/totalview';

  @override
  Widget build(BuildContext context) {
    final invViewmodel = Provider.of<InvViewModel>(context);

    const Color primaryDark = Colors.black;
    const Color accentGreen = Colors.lightGreenAccent;
    const Color textColor = Colors.white;

    Color getNplColor(double val) => val >= 0 ? accentGreen : Colors.redAccent;

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: accentGreen,
        elevation: 0,
        title: const Text(
          "RESUMEN GENERAL",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    "VALOR TOTAL",
                    style: TextStyle(
                      color: accentGreen.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${invViewmodel.totalCurrentValue.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoTile(
              "Inversión Inicial",
              '${invViewmodel.totalInvestment.toStringAsFixed(2)}€',
              Colors.white,
            ),
            _buildInfoTile(
              "Ganancia/Pérdida Absoluta",
              '${invViewmodel.totalPnL.toStringAsFixed(2)}€',
              getNplColor(invViewmodel.totalPnL),
            ),
            _buildInfoTile(
              "Rendimiento Porcentual",
              '${invViewmodel.totalPnLPercent.toStringAsFixed(2)}%',
              getNplColor(invViewmodel.totalPnLPercent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

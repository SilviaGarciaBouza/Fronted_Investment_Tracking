import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';
import '../utils/app_strings.dart';
import '../theme/app_theme.dart';

class TotalView extends StatelessWidget {
  const TotalView({super.key});
  static const routeName = '/totalview';

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final bg = theme.scaffoldBackgroundColor;
    final cs = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;

    Color getNplColor(double val) => val >= 0 ? primary : appColors.pnlNegative;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.get('back_tooltip', lang),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppStrings.get('total_res', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: AppStrings.get('tooltip_print', lang),
            onPressed: () async {
              final pdfDoc = await vm.generateGeneralReport();

              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdfDoc.save(),
                name:
                    'informe_investtrackin_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      child: Text(AppStrings.get('pdf_generated', lang)),
                    ),
                    backgroundColor: primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.get('total_val', lang),
                    style: TextStyle(
                      color: primary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${vm.totalCurrentValue.toStringAsFixed(2)}€',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _infoTile(
              context,
              AppStrings.get('init_inv', lang),
              '${vm.totalInvestment.toStringAsFixed(2)}€',
              cs.onSurface,
            ),
            _infoTile(
              context,
              AppStrings.get('abs_pnl', lang),
              '${vm.totalPnL.toStringAsFixed(2)}€',
              getNplColor(vm.totalPnL),
            ),
            _infoTile(
              context,
              AppStrings.get('perc_pnl', lang),
              '${vm.totalPnLPercent.toStringAsFixed(2)}%',
              getNplColor(vm.totalPnLPercent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/utils/app_strings.dart';

class Additem extends StatefulWidget {
  const Additem({super.key});
  static const routeName = '/additem';

  @override
  State<Additem> createState() => _AdditemState();
}

class _AdditemState extends State<Additem> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int? _selectedCatId;
  String? _selectedCategoryName;
  String? _selectedAssetName;

  final Map<String, List<String>> _assetsByCategory = {
    'Acción': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA'],
    'Criptomoneda': ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'ADAUSDT', 'XRPUSDT'],
    'Divisa': ['EUR/USD', 'EUR/GBP', 'EUR/JPY', 'EUR/CHF'],
  };

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_onFieldsChanged);
    _priceController.addListener(_onFieldsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvViewModel>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() => setState(() {});

  bool _isFormValid() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return _selectedCatId != null &&
        _selectedAssetName != null &&
        qty > 0 &&
        price > 0;
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final isValid = _isFormValid();

    final theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color primaryColor = theme.primaryColor;
    final cs = theme.colorScheme;
    final Color textColor = cs.onSurface;
    final Color fieldColor = cs.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.get('back_tooltip', lang),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          AppStrings.get('new_inv', lang),
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(AppStrings.get('cat_label', lang), primaryColor),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              dropdownColor: fieldColor,
              initialValue: _selectedCatId,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                AppStrings.get('cat_hint', lang),
                Icons.category_outlined,
                primaryColor,
                fieldColor,
              ),
              items: vm.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        AppStrings.get(c.name, lang),
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                final catName = vm.categories
                    .firstWhereOrNull((c) => c.id == val)
                    ?.name;
                if (catName == null) {
                  return;
                }
                setState(() {
                  _selectedCatId = val;
                  _selectedCategoryName = catName;
                  _selectedAssetName = null;
                });
              },
            ),

            const SizedBox(height: 25),

            _label(AppStrings.get('asset_label', lang), primaryColor),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              dropdownColor: fieldColor,
              initialValue: _selectedAssetName,
              disabledHint: Text(
                AppStrings.get('asset_wait', lang),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(
                AppStrings.get('asset_hint', lang),
                Icons.auto_graph,
                primaryColor,
                fieldColor,
              ),
              items: _selectedCategoryName == null
                  ? null
                  : (_assetsByCategory[_selectedCategoryName] ?? [])
                        .map(
                          (name) => DropdownMenuItem(
                            value: name,
                            child: Text(
                              name,
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        )
                        .toList(),
              onChanged: (val) => setState(() => _selectedAssetName = val),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(AppStrings.get('qty_label', lang), primaryColor),
                      const SizedBox(height: 10),
                      _textField(
                        _qtyController,
                        "Ej: 0.5",
                        primaryColor,
                        fieldColor,
                        textColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(AppStrings.get('price_label', lang), primaryColor),
                      const SizedBox(height: 10),
                      _textField(
                        _priceController,
                        "0.00 €",
                        primaryColor,
                        fieldColor,
                        textColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            vm.isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor: cs.surfaceContainerHighest,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isValid
                        ? () async {
                            final result = await vm.saveNewItem(
                              name: _selectedAssetName!,
                              stocks: double.parse(_qtyController.text),
                              price: double.parse(_priceController.text),
                              categoryId: _selectedCatId!,
                            );
                            if (mounted) Navigator.pop(context, result);
                          }
                        : null,
                    child: Text(
                      isValid
                          ? AppStrings.get('btn_confirm', lang)
                          : AppStrings.get('btn_incomplete', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
  );

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color primary,
    Color field,
  ) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 14,
    ),
    prefixIcon: Icon(icon, color: primary),
    filled: true,
    fillColor: field,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: primary),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String hint,
    Color primary,
    Color field,
    Color text,
  ) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: TextStyle(color: text),
    decoration: _inputDecoration(hint, Icons.edit_note, primary, field),
  );
}

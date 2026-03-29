import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';

class Additem extends StatefulWidget {
  const Additem({super.key});
  static const routeName = '/additem';

  @override
  State<Additem> createState() => _AdditemState();
}

class _AdditemState extends State<Additem> {
  final Color _black = Colors.black;
  final Color _greenAccent = Colors.lightGreenAccent;
  final Color _fieldColor = Colors.grey.shade900;

  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int? _selectedCatId;
  String? _selectedCategoryName;
  String? _selectedAssetName;

  final Map<String, List<String>> _assetsByCategory = {
    'Acción': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA'],
    'Criptomoneda': ['BTC/EUR', 'ETH/EUR', 'SOL/EUR', 'ADA/EUR', 'XRP/EUR'],
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
    final isValid = _isFormValid();

    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: _black,
        elevation: 0,
        title: Text(
          "NUEVA INVERSIÓN",
          style: TextStyle(
            color: _greenAccent,
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
            _label("1. CATEGORÍA"),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              dropdownColor: _fieldColor,
              value: _selectedCatId,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                "Selecciona categoría",
                Icons.category_outlined,
              ),
              items: vm.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCatId = val;
                  _selectedCategoryName = vm.categories
                      .firstWhere((c) => c.id == val)
                      .name;
                  _selectedAssetName = null;
                });
              },
            ),

            const SizedBox(height: 25),

            _label("2. ACTIVO"),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              dropdownColor: _fieldColor,
              value: _selectedAssetName,
              disabledHint: const Text(
                "Elige categoría primero",
                style: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                "Selecciona activo",
                Icons.auto_graph,
              ),
              items: _selectedCategoryName == null
                  ? null
                  : (_assetsByCategory[_selectedCategoryName] ?? [])
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
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
                      _label("CANTIDAD (> 0)"),
                      const SizedBox(height: 10),
                      _textField(_qtyController, "Ej: 0.5"),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("PRECIO (€ > 0)"),
                      const SizedBox(height: 10),
                      _textField(_priceController, "0.00 €"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            vm.isLoading
                ? Center(child: CircularProgressIndicator(color: _greenAccent))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenAccent,
                      foregroundColor: _black,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade500,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Si el formulario no es válido, onPressed es NULL (botón desactivado)
                    onPressed: isValid
                        ? () async {
                            await vm.saveNewItem(
                              name: _selectedAssetName!,
                              stocks: double.parse(_qtyController.text),
                              price: double.parse(_priceController.text),
                              categoryId: _selectedCatId!,
                            );
                            if (mounted) Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      isValid ? "CONFIRMAR OPERACIÓN" : "COMPLETA LOS DATOS",
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

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      color: _greenAccent,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _greenAccent),
        filled: true,
        fillColor: _fieldColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _greenAccent),
        ),
      );

  Widget _textField(TextEditingController controller, String hint) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(color: Colors.white),
    decoration: _inputDecoration(hint, Icons.edit_note),
  );
}

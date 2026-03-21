import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as model;

/// Vista para añadir una nueva inversión.
class Additem extends StatefulWidget {
  const Additem({super.key});
  static const routeName = '/additem';

  @override
  State<Additem> createState() => _AddItemState();
}

class _AddItemState extends State<Additem> {
  final Color _primaryDark = Colors.black;
  final Color _accentGreen = Colors.lightGreenAccent;
  final Color _textColor = Colors.white;
  final Color _fieldFillColor = Colors.grey.shade900;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  int? selectedCategoryId;
  String? selectedAssetName;
  String? selectedCategoryName;

  /// Mapa de activos por categoría
  final Map<String, List<String>> _assetsByCategory = {
    'Acción': ['AAPL', 'MSFT', 'AMZN', 'GOOGL', 'TSLA', 'NVDA'],
    'Criptomoneda': [
      'BTC/USD',
      'ETH/USD',
      'SOL/USD',
      'ADA/USD',
      'DOT/USD',
      'DOGE/USD',
    ],
    'Divisa': ['EUR/USD', 'GBP/USD', 'USD/JPY', 'EUR/GBP'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Invviewmodel>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invViewModel = Provider.of<Invviewmodel>(context);

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: _accentGreen,
        elevation: 0,
        title: const Text(
          "NUEVA INVERSIÓN",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("1. SELECCIONA CATEGORÍA"),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              dropdownColor: _fieldFillColor,
              style: TextStyle(color: _textColor),
              decoration: _inputDecoration(
                "Categoría",
                Icons.category_outlined,
              ),
              value: selectedCategoryId,
              hint: Text(
                "Elige una categoría",
                style: TextStyle(color: _textColor.withOpacity(0.3)),
              ),
              items: invViewModel.categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.id,
                  child: Text(cat.name, style: TextStyle(color: _textColor)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategoryId = val;
                  selectedCategoryName = invViewModel.categories
                      .firstWhere((c) => c.id == val)
                      .name;
                  selectedAssetName = null;
                });
              },
            ),

            const SizedBox(height: 25),

            _buildLabel("2. SELECCIONA ACTIVO"),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: _fieldFillColor,
              disabledHint: const Text(
                "Elige primero categoría",
                style: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: _textColor),
              decoration: _inputDecoration("Activo", Icons.auto_graph),
              value: selectedAssetName,
              items: selectedCategoryName == null
                  ? []
                  : (_assetsByCategory[selectedCategoryName] ?? []).map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name, style: TextStyle(color: _textColor)),
                      );
                    }).toList(),
              onChanged: (val) => setState(() => selectedAssetName = val),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("CANTIDAD"),
                      const SizedBox(height: 8),
                      _buildTextField(
                        quantityController,
                        "0.00",
                        Icons.add_chart,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("PRECIO COMPRA (€)"),
                      const SizedBox(height: 8),
                      _buildTextField(priceController, "0.00", Icons.euro),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            invViewModel.isLoading
                ? Center(child: CircularProgressIndicator(color: _accentGreen))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: _primaryDark,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (selectedCategoryId == null ||
                          selectedAssetName == null ||
                          quantityController.text.isEmpty ||
                          priceController.text.isEmpty) {
                        _showError("Por favor, completa todos los campos");
                        return;
                      }

                      final stocks =
                          double.tryParse(quantityController.text) ?? 0.0;
                      final price =
                          double.tryParse(priceController.text) ?? 0.0;

                      await invViewModel.saveNewItem(
                        name: selectedAssetName!,
                        stocks: stocks,
                        price: price,
                        categoryId: selectedCategoryId!,
                      );

                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      "CONFIRMAR INVERSIÓN",
                      style: TextStyle(
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _accentGreen,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textColor.withOpacity(0.3)),
      prefixIcon: Icon(icon, color: _accentGreen),
      filled: true,
      fillColor: _fieldFillColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _accentGreen),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: _textColor),
      decoration: _inputDecoration(hint, icon),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
    );
  }
}

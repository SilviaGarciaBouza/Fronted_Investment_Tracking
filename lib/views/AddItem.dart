import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/models/Transaction.dart';

class Additem extends StatefulWidget {
  const Additem({super.key});
  static const routeName = '/additem';

  @override
  State<Additem> createState() => _AddItem();
}

class _AddItem extends State<Additem> {
  final Color _primaryDark = Colors.black;
  final Color _accentGreen = Colors.lightGreenAccent;
  final Color _textColor = Colors.white;
  final Color _fieldBorderColor = Colors.grey.shade700;
  final Color _fieldFillColor = Colors.grey.shade900;
  // -----------------------------

  final List<String> availableSymbols = [
    // Acciones
    'AAPL', // Apple
    'GOOGL', // Alphabet
    'TSLA', // Tesla
    //Criptos
    'BTC', // Bitcoin
    'ETH', // Ethereum
    'SOL', // Solana
    //Divisas
    'EURUSD', // Euro / Dólar
    'GBPUSD', // Libra / Dólar
    'USDJPY', // Dólar / Yen
  ];

  String? selectedSymbol;
  late TextEditingController categoryController;
  late TextEditingController quantityController;
  late TextEditingController purchasePriceController;

  String _getCategoryFromSymbol(String symbol) {
    const cryptoSymbols = ['BTC', 'ETH', 'SOL'];

    if (symbol.length == 6 && symbol.contains(RegExp(r'[A-Z]'))) {
      return 'Divisa';
    }

    if (cryptoSymbols.contains(symbol)) {
      return 'Criptomoneda';
    }

    return 'Acción';
  }

  @override
  void initState() {
    super.initState();
    categoryController = TextEditingController();
    quantityController = TextEditingController();
    purchasePriceController = TextEditingController();
    selectedSymbol = availableSymbols.first;
    categoryController.text = _getCategoryFromSymbol(selectedSymbol!);
  }

  @override
  void dispose() {
    categoryController.dispose();
    quantityController.dispose();
    purchasePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invViewModel = Provider.of<Invviewmodel>(context, listen: false);

    InputDecoration _inputDecoration(String label) {
      return InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _fieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _fieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _accentGreen, width: 2),
        ),
        labelText: label,
        labelStyle: TextStyle(color: _fieldBorderColor),
        filled: true,
        fillColor: _fieldFillColor,
      );
    }

    return Scaffold(
      backgroundColor: _primaryDark,
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: _accentGreen,
        title: Center(
          child: Text(
            "My investment",
            style: TextStyle(color: _accentGreen, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: _inputDecoration(
                  'Asset Symbol (Stock, Crypto, FX)',
                ),
                dropdownColor: _fieldFillColor,
                style: TextStyle(color: _textColor),
                icon: Icon(Icons.arrow_drop_down, color: _accentGreen),
                value: selectedSymbol,
                items: availableSymbols.map((String symbol) {
                  return DropdownMenuItem<String>(
                    value: symbol,
                    child: Text(symbol, style: TextStyle(color: _textColor)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSymbol = newValue;
                    if (newValue != null) {
                      categoryController.text = _getCategoryFromSymbol(
                        newValue,
                      );
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Por favor, selecciona un símbolo.' : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: categoryController,
                readOnly: true,
                style: TextStyle(color: _textColor),
                decoration: _inputDecoration(
                  'Category (Autofilled)',
                ).copyWith(labelStyle: TextStyle(color: _fieldBorderColor)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _textColor),
                decoration: _inputDecoration('Quantity (Shares, Coins, Units)'),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: purchasePriceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _textColor),
                decoration: _inputDecoration(
                  'Purchase Price (€ per share/unit)',
                ),
              ),
            ),

            const SizedBox(height: 20),

            Flexible(
              child: ElevatedButton(
                onPressed: () async {
                  final name = selectedSymbol;
                  final category = categoryController.text.trim();
                  final quantityText = quantityController.text.trim();
                  final purchasePriceText = purchasePriceController.text.trim();
                  if (name == null ||
                      category.isEmpty ||
                      quantityText.isEmpty ||
                      purchasePriceText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor, rellena todos los campos.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final stocks = double.tryParse(quantityText);
                  final purchasePrice = double.tryParse(purchasePriceText);
                  if (stocks == null ||
                      stocks <= 0 ||
                      purchasePrice == null ||
                      purchasePrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cantidad y Precio de Compra deben ser números válidos y positivos.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final invEurInitial = stocks * purchasePrice;

                  final initialTransaction = Transaction(
                    date: DateTime.now(),
                    stocks: stocks,
                    purchasePrice: purchasePrice,
                    invEur: invEurInitial,
                  );

                  final newItem = Item(
                    category: category,
                    currentPercentaje: 0.0,
                    name: name,
                    idItem: invViewModel.getList().length.toDouble() + 1,
                    stocks: stocks,
                    sharePrize: purchasePrice,
                    invEur: invEurInitial,
                    valueEur: invEurInitial,
                    nRpL: 0.0,
                    nRPlPercentaje: 0.0,
                    transactions: [initialTransaction],
                  );

                  Navigator.pop(context, newItem);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: _primaryDark,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

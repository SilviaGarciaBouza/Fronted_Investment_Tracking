import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:provider/provider.dart';

class Additem extends StatefulWidget {
  const Additem({super.key});
  static const routeName = '/additem';

  @override
  State<Additem> createState() => _AddItem();
}

class _AddItem extends State<Additem> {
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

    selectedSymbol = availableSymbols.first;
    categoryController.text = _getCategoryFromSymbol(selectedSymbol!);
  }

  @override
  void dispose() {
    categoryController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invViewModel = Provider.of<Invviewmodel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Center(
          child: Text("My investment", style: TextStyle(color: Colors.green)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Asset Symbol (Stock, Crypto, FX)',
                ),
                value: selectedSymbol,
                items: availableSymbols.map((String symbol) {
                  return DropdownMenuItem<String>(
                    value: symbol,
                    child: Text(symbol),
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

            // ------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: categoryController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Category (Autofilled)',
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantity (Shares, Coins, Units)',
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

                  if (name == null ||
                      category.isEmpty ||
                      quantityText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, rellena todos los campos.'),
                      ),
                    );
                    return;
                  }

                  final stocks = double.tryParse(quantityText);
                  if (stocks == null || stocks <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cantidad debe ser un número válido y positivo.',
                        ),
                      ),
                    );
                    return;
                  }

                  final newItem = Item(
                    category: category,
                    currentPercentaje: 0.0,
                    name: name,
                    idItem: invViewModel.getList().length.toDouble() + 1,
                    stocks: stocks,
                    sharePrize: 0.0,
                    invEur: 0.0,
                    valueEur: 0.0,
                    nRpL: 0.0,
                    nRPlPercentaje: 0.0,
                  );

                  Navigator.pop(context, newItem);
                },

                child: const Text("Add"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

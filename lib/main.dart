import 'package:flutter/material.dart';
import 'package:investment_tracking/widgets/AlertDialogAddItemWidget.dart';
import 'package:investment_tracking/widgets/HeaderWidget.dart';
import 'package:investment_tracking/widgets/Item.dart';
import 'package:investment_tracking/widgets/ItemFieldWidget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      home: const MyHomePage(title: 'Investment portfolio'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Item> myList = [];
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final sharePrizeController = TextEditingController();
  final stocksController = TextEditingController();
  final invEurController = TextEditingController();

  void _clearTextControllers() {
    nameController.clear();
    categoryController.clear();
    sharePrizeController.clear();
    stocksController.clear();
    invEurController.clear();
  }

  void addItem() {
    setState(() {
      _showAddItemDialog(context);
    });
  }

  void _showAddItemDialog(BuildContext context) {
    _clearTextControllers();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Alertdialogadditemwidget(
          nameController: nameController,
          categoryController: categoryController,
          sharePrizeController: sharePrizeController,
          stocksController: stocksController,
          invEurController: invEurController,

          onCancel: () {
            _clearTextControllers();
            Navigator.of(dialogContext).pop();
          },

          onAdd: () {
            addNewItemLogic(dialogContext);
          },
          isLoadingGeneric: true,
          popularTickers: List.empty(),
          onTickerSelect: (String ticker) async {},
        );
      },
    );
  }

  void addNewItemLogic(BuildContext dialogContext) {
    final name = nameController.text;
    final category = categoryController.text;
    final sharePrize = double.tryParse(sharePrizeController.text) ?? 0.0;
    final stocks = double.tryParse(stocksController.text) ?? 0.0;
    final invEur = double.tryParse(invEurController.text) ?? 0.0;
    final valueEur = sharePrize * stocks;

    if (name.isNotEmpty && category.isNotEmpty && invEur > 0.0) {
      final newItem = Item(
        category: category,
        name: name,
        sharePrize: sharePrize,
        stocks: stocks,
        invEur: invEur,
        valueEur: valueEur,
        idItem: (myList.length + 1).toDouble(),
        nRpL: valueEur - invEur,
        nRPlPercentaje: invEur > 0 ? ((valueEur - invEur) / invEur) * 100 : 0.0,
        currentPercentaje: 0.0,
      );

      setState(() {
        myList.add(newItem);
        _clearTextControllers();
      });

      Navigator.of(dialogContext).pop();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    sharePrizeController.dispose();
    stocksController.dispose();
    invEurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Center(child: Text(widget.title)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.05,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Headerwidget(),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: myList.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      ItemFieldWidget(
                        numFlex: 2,
                        childText: myList[index].category,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 2,
                        childText: myList[index].currentPercentaje
                            .toStringAsFixed(2),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 3,
                        childText: myList[index].name,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 1,
                        childText: myList[index].idItem.toStringAsFixed(0),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 2,
                        childText: myList[index].sharePrize.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 1,
                        childText: myList[index].stocks.toStringAsFixed(0),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 2,
                        childText: myList[index].valueEur.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 2,
                        childText: myList[index].nRpL.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(width: 8),

                      ItemFieldWidget(
                        numFlex: 2,
                        childText:
                            '${myList[index].nRPlPercentaje.toStringAsFixed(2)}%',
                        textAlign: TextAlign.end,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addItem,
        tooltip: 'New item',
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

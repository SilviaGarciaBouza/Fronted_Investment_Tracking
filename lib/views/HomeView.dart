import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/views/TotalView.dart';
import 'package:investment_tracking/views/TransactionDetailView.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/';
  @override
  State<Homeview> createState() => _Homeview();
}

class _Homeview extends State<Homeview> {
  final Color _black = Colors.black;
  final Color _greenAccent = Colors.lightGreenAccent;
  final Color _textColor = Colors.white;
  final Color _headerColor = Colors.grey.shade400;

  Color _getNplColor(double nRPlPercentaje) {
    if (nRPlPercentaje > 0) {
      return _greenAccent;
    } else if (nRPlPercentaje < 0) {
      return Colors.redAccent;
    } else {
      return _textColor.withOpacity(0.8);
    }
  }

  void _deleteItem(
    BuildContext context,
    Invviewmodel invViewmodel,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _black,
          title: Text(
            'Confirmar eliminación',
            style: TextStyle(color: _textColor),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar la inversión en $itemName?',
            style: TextStyle(color: _textColor.withOpacity(0.8)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _headerColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                invViewmodel.removeItem(itemName);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Inversión en $itemName eliminada.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invViewmodel = Provider.of<Invviewmodel>(context);
    final Color black = Colors.black;
    final Color greenAccent = Colors.lightGreenAccent;
    final Color textColor = Colors.white;
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        backgroundColor: black,
        title: Center(
          child: Text(
            "My investment",
            style: TextStyle(color: greenAccent, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.show_chart, color: greenAccent),
            onPressed: () {
              Navigator.pushNamed(context, TotalView.routeName);
            },
          ),
        ],
      ),
      body: invViewmodel.isLoading
          ? Center(child: CircularProgressIndicator(color: greenAccent))
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Id",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Name",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Category",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Stocks",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "%",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Share prize",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "inv(€)",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Value(€)",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "nRpL",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "nRpL %",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _headerColor, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 40, child: Text('')),
                    ],
                  ),
                  Divider(color: _headerColor.withOpacity(0.5)),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var element in invViewmodel.getList())
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    element.idItem.toStringAsFixed(0),
                                    style: TextStyle(color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final selectedItem = invViewmodel
                                          .getItemByName(element.name);
                                      if (selectedItem != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TransactionDetailView(
                                                  item: selectedItem,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      element.name,
                                      style: TextStyle(
                                        color: textColor,
                                        decoration: TextDecoration.underline,
                                        decorationColor: greenAccent,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    element.category,
                                    style: TextStyle(color: _headerColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    element.stocks.toStringAsFixed(2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.currentPercentaje.toStringAsFixed(2)}%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.sharePrize.toStringAsFixed(2)}€',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.invEur.toStringAsFixed(2)}€',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.valueEur.toStringAsFixed(2)}€',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.nRpL.toStringAsFixed(2)}€',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _getNplColor(element.nRpL),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${element.nRPlPercentaje.toStringAsFixed(2)}%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _getNplColor(
                                        element.nRPlPercentaje,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _deleteItem(
                                        context,
                                        invViewmodel,
                                        element.name,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Item>(
            context,
            MaterialPageRoute(builder: (context) => const Additem()),
          );

          if (!mounted) return;

          if (result != null) {
            await invViewmodel.addItem(result);
          }
        },
        backgroundColor: greenAccent,
        foregroundColor: black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

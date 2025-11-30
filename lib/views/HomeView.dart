import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:provider/provider.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/';
  @override
  State<Homeview> createState() => _Homeview();
}

class _Homeview extends State<Homeview> {
  void _deleteItem(
    BuildContext context,
    Invviewmodel invViewmodel,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar la inversión en $itemName?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                style: TextStyle(color: Colors.red),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Center(
          child: Text(
            "My investment",
            style: TextStyle(color: Colors.green),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Id",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "Name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "Category",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "Stocks",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "%",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "Share prize",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "inv(€)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "Value(€)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "nRpL",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(
                  child: Text(
                    "nRpL %",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 40, child: Text('')),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (var element in invViewmodel.getList())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(element.idItem.toString())),
                          Expanded(child: Text(element.name)),
                          Expanded(child: Text(element.category)),
                          Expanded(
                            child: Text(
                              element.stocks.toStringAsFixed(2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.currentPercentaje.toStringAsFixed(2)}%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.sharePrize.toStringAsFixed(2)}€',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.invEur.toStringAsFixed(2)}€',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.valueEur.toStringAsFixed(2)}€',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.nRpL.toStringAsFixed(2)}€',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${element.nRPlPercentaje.toStringAsFixed(2)}%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
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

        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:provider/provider.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/';
   @override
  State<Homeview> createState() => _Homeview();
}
class _Homeview extends State<Homeview>{
  @override
  Widget build(BuildContext context) {
    final invViewmodel = Provider.of<Invviewmodel>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
          child: Text("My investment", style: TextStyle(color: Colors.green)),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text("Id")),
                Expanded(child: Text("Name")),
                Expanded(child: Text("Category")),
                Expanded(child: Text("Stocks")),
                Expanded(child: Text("%")),
                Expanded(child: Text("Share prize")),
                Expanded(child: Text("inv(€)")),
                Expanded(child: Text("Value(€)")),
                Expanded(child: Text("nRpL")),
                Expanded(child: Text("nRpL %")),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (var element in invViewmodel.getList())
                    Row(
                      children: [
                        Expanded(child: Text(element.idItem.toString())),
                        Expanded(child: Text(element.name)),
                        Expanded(child: Text(element.category)),
                        Expanded(
                          child: Text(element.stocks.toStringAsFixed(2)),
                        ),
                        Expanded(
                          child: Text(
                            '${element.currentPercentaje.toStringAsFixed(2)}%',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${element.sharePrize.toStringAsFixed(2)}€',
                          ),
                        ),
                        Expanded(
                          child: Text('${element.invEur.toStringAsFixed(2)}€'),
                        ),
                        Expanded(
                          child: Text(
                            '${element.valueEur.toStringAsFixed(2)}€',
                          ),
                        ),
                        Expanded(
                          child: Text('${element.nRpL.toStringAsFixed(2)}€'),
                        ),
                        Expanded(
                          child: Text(
                            '${element.nRPlPercentaje.toStringAsFixed(2)}%',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => async: {
          final result= await Navigator.push(
            context, 
            Additem.routeName);
        },

        backgroundCoor: Colors.green.shade700,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: Icon(Icons.add),

      ),
    );
  }
}

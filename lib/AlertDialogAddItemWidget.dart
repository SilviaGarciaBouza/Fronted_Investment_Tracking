import 'package:flutter/material.dart';

class Alertdialogadditemwidget extends StatelessWidget {
  const Alertdialogadditemwidget({
    super.key,
    required this.nameController,
    required this.categoryController,
    required this.sharePrizeController,
    required this.stocksController,
    required this.invEurController,
    required this.onCancel,
    required this.onAdd,
  });
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController sharePrizeController;
  final TextEditingController stocksController;
  final TextEditingController invEurController;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
      hintStyle: const TextStyle(color: Colors.white70),
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.green, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
    );

    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: const Text(
        'Add New Investment Item',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
        ),
      ),
      content: SingleChildScrollView(
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(inputDecorationTheme: inputDecorationTheme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sharePrizeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Share Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: stocksController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Stocks Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: invEurController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Invested (EUR)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70, fontSize: 16.0),
          ),
        ),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

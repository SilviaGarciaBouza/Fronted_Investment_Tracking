import 'package:flutter/material.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';
import 'AddItem.dart';
import 'total_view.dart';
import 'TransactionDetailView.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/home';

  @override
  State<Homeview> createState() => _Homeview();
}

class _Homeview extends State<Homeview> {
  final Color _black = Colors.black;
  final Color _greenAccent = Colors.lightGreenAccent;
  final Color _textColor = Colors.white;
  final Color _headerColor = Colors.grey.shade400;

  Color _getNplColor(double percentage) {
    if (percentage > 0) return _greenAccent;
    if (percentage < 0) return Colors.redAccent;
    return _textColor.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al ViewModel
    final invViewmodel = Provider.of<Invviewmodel>(context);

    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: _black,
        elevation: 0,
        title: Text(
          "MY INVESTMENTS",
          style: TextStyle(
            color: _greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.show_chart, color: _greenAccent),
            onPressed: () => Navigator.pushNamed(context, TotalView.routeName),
          ),
        ],
      ),
      body: invViewmodel.isLoading && invViewmodel.itemList.isEmpty
          ? Center(child: CircularProgressIndicator(color: _greenAccent))
          : RefreshIndicator(
              color: _greenAccent,
              onRefresh: () => invViewmodel.fetchItems(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Cabecera de la tabla
                    _buildHeader(),
                    Divider(color: _headerColor.withOpacity(0.3)),

                    // Lista de activos desde MariaDB
                    Expanded(
                      child: invViewmodel.itemList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: invViewmodel.itemList.length,
                              itemBuilder: (context, index) {
                                final item = invViewmodel.itemList[index];
                                return _buildItemRow(item, invViewmodel);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, Additem.routeName);
          // Al volver, refrescamos los datos por si se ha añadido algo
          //invViewmodel.fetchItems();
        },
        backgroundColor: _greenAccent,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  // Widget para la cabecera
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "NAME",
            style: TextStyle(
              color: _headerColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "STOCKS",
            style: TextStyle(
              color: _headerColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "VALUE(€)",
            style: TextStyle(
              color: _headerColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "PnL %",
            style: TextStyle(
              color: _headerColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // Widget para cada fila de la inversión
  Widget _buildItemRow(Item element, Invviewmodel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailView(item: element),
                  ),
                );
              },
              child: Text(
                element.name,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: _greenAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              element.stocks.toStringAsFixed(2),
              style: TextStyle(color: _textColor),
            ),
          ),
          Expanded(
            child: Text(
              '${element.valueEur.toStringAsFixed(2)}€',
              style: TextStyle(color: _textColor),
            ),
          ),
          Expanded(
            child: Text(
              '${element.nRPlPercentaje.toStringAsFixed(2)}%',
              style: TextStyle(
                color: _getNplColor(element.nRPlPercentaje),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: _black,
                  title: Text(
                    "¿Borrar ${element.name}?",
                    style: TextStyle(color: _textColor),
                  ),
                  content: Text(
                    "Esta acción no se puede deshacer.",
                    style: TextStyle(color: _headerColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCELAR",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        vm.deleteItem(element.id);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "BORRAR",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No hay inversiones. ¡Pulsa + para añadir!",
        style: TextStyle(color: _headerColor),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/total_view.dart';
import 'package:investment_tracking/views/TransactionDetailView.dart';
import 'package:investment_tracking/views/LoginView.dart';
import '../models/item.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/home';

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  final Color _black = Colors.black;
  final Color _greenAccent = Colors.lightGreenAccent;
  final Color _headerColor = Colors.grey.shade500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvViewModel>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);

    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: _black,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            vm.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: vm.isOnline ? _greenAccent : Colors.redAccent,
          ),
          tooltip: vm.isOnline
              ? "Sincronizado con la base de datos"
              : "Modo local: Sin conexión",
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  vm.isOnline
                      ? "Sincronizando con MariaDB..."
                      : "Modo Offline: Usando base de datos local",
                  style: TextStyle(
                    color: vm.isOnline
                        ? Colors.lightGreenAccent
                        : Colors.redAccent,
                  ),
                ),

                duration: Duration(seconds: 3),
              ),
            );
            await vm.fetchItems();
          },
        ),

        title: Text(
          "MY PORTFOLIO",
          style: TextStyle(
            color: _greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.leaderboard_outlined, color: _greenAccent),
            tooltip: "Ver resumen de beneficios totales",
            onPressed: () => Navigator.pushNamed(context, TotalView.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Cerrar sesión de ${vm.currentUser?.username}",
            onPressed: () async {
              await vm.logout();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, LoginView.routeName);
            },
          ),
        ],
      ),
      body: vm.isLoading && vm.itemList.isEmpty
          ? Center(child: CircularProgressIndicator(color: _greenAccent))
          : RefreshIndicator(
              color: _greenAccent,
              backgroundColor: _black,
              onRefresh: () => vm.fetchItems(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: vm.itemList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: vm.itemList.length,
                              itemBuilder: (context, index) =>
                                  _buildItemRow(vm.itemList[index], vm),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _greenAccent,
        tooltip: "Registrar nueva inversión",
        onPressed: () async {
          await Navigator.pushNamed(context, Additem.routeName);

          if (context.mounted) {
            Provider.of<InvViewModel>(context, listen: false).fetchItems();
          }
        },
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("ACTIVO", style: _headerStyle())),
          Expanded(flex: 2, child: Text("CANT.", style: _headerStyle())),
          Expanded(flex: 2, child: Text("VALOR", style: _headerStyle())),
          Expanded(flex: 2, child: Text("PnL %", style: _headerStyle())),
          const SizedBox(width: 35),
        ],
      ),
    );
  }

  TextStyle _headerStyle() =>
      TextStyle(color: _headerColor, fontSize: 10, fontWeight: FontWeight.bold);

  /// Fila personalizada por cada activo .
  Widget _buildItemRow(Item element, InvViewModel vm) {
    Color pnlColor = element.profitPercent >= 0
        ? _greenAccent
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Tooltip(
        message: "Ver detalles y transacciones de ${element.name}",

        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailView(item: element),
            ),
          ),

          title: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (!element.isSynced)
                      Text(
                        "PENDIENTE SYNC",
                        style: TextStyle(
                          color: _greenAccent.withOpacity(0.5),
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  element.totalStocks.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "${element.currentValue.toStringAsFixed(2)}€",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "${element.profitPercent.toStringAsFixed(2)}%",
                  style: TextStyle(
                    color: pnlColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: "Borrar activo de la cartera",
                onPressed: () => _confirmDelete(element, vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Item item, InvViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          "¿Eliminar ${item.name}?",
          style: const TextStyle(color: Colors.white),
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
              vm.deleteItem(item.id!, item.serverId);
              Navigator.pop(context);
            },
            child: const Text(
              "BORRAR",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: _headerColor,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text("Cartera vacía", style: TextStyle(color: _headerColor)),
        ],
      ),
    );
  }
}

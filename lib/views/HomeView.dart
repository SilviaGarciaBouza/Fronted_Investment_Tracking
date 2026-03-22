import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import 'AddItem.dart';
import 'total_view.dart';
import 'TransactionDetailView.dart';

/// Vista principal de la aplicación (Home).
///
/// Muestra el listado de activos de la cartera, el estado de sincronización
/// y permite acceder a la creación de nuevos items o al detalle de transacciones.
class Homeview extends StatefulWidget {
  const Homeview({super.key});

  /// Nombre de la ruta para la navegación.
  static const routeName = '/home';

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  final Color _black = Colors.black;
  final Color _greenAccent = Colors.lightGreenAccent;
  final Color _textColor = Colors.white;
  final Color _headerColor = Colors.grey.shade500;

  @override
  void initState() {
    super.initState();

    /// Carga inicial de items al renderizar la pantalla por primera vez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<Invviewmodel>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invViewModel = Provider.of<Invviewmodel>(context);

    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: _black,
        elevation: 0,

        /// Icono indicador de estado de red (Online/Offline).
        leading: IconButton(
          icon: Icon(
            invViewModel.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: invViewModel.isOnline ? _greenAccent : Colors.redAccent,
            size: 22,
          ),
          onPressed: () async {
            bool syncOk = await invViewModel.syncEverything();

            await invViewModel.fetchItems();

            if (context.mounted) {
              if (invViewModel.isOnline && syncOk) {
                _showSnackBar(context, "Sincronización finalizada con éxito ");
              } else {
                _showSnackBar(
                  context,
                  "Error al sincronizar datos ",
                  isError: true,
                );
              }
            }
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
          /// Botón para ver el resumen total de la cartera.
          IconButton(
            icon: Icon(Icons.leaderboard_outlined, color: _greenAccent),
            onPressed: () => Navigator.pushNamed(context, TotalView.routeName),
          ),
          //boton logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Cerrar Sesión",
            onPressed: () async {
              await invViewModel.logout();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: invViewModel.isLoading && invViewModel.itemList.isEmpty
          ? Center(child: CircularProgressIndicator(color: _greenAccent))
          : RefreshIndicator(
              color: _greenAccent,
              backgroundColor: _black,
              onRefresh: () => invViewModel.fetchItems(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: invViewModel.itemList.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: invViewModel.itemList.length,
                              itemBuilder: (context, index) {
                                final item = invViewModel.itemList[index];
                                return _buildItemRow(item, invViewModel);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _greenAccent,
        onPressed: () => Navigator.pushNamed(context, Additem.routeName),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  /// Construye la cabecera de la tabla de inversiones.
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

  /// Construye una fila individual para cada inversión.
  ///
  /// [element] es el objeto Item a mostrar.
  /// [vm] es la instancia del ViewModel para gestionar acciones.
  Widget _buildItemRow(Item element, Invviewmodel vm) {
    Color pnlColor = element.nRPlPercentaje > 0
        ? _greenAccent
        : (element.nRPlPercentaje < 0 ? Colors.redAccent : _textColor);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
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
                element.stocks.toStringAsFixed(2),
                style: TextStyle(color: _textColor, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${element.valueEur.toStringAsFixed(2)}€",
                style: TextStyle(color: _textColor, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${element.nRPlPercentaje.toStringAsFixed(2)}%",
                style: TextStyle(
                  color: pnlColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(element, vm),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar una inversión.
  void _showDeleteDialog(Item element, Invviewmodel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          "¿Eliminar ${element.name}?",
          style: TextStyle(color: _textColor),
        ),
        content: const Text(
          "La inversión desaparecerá de tu vista. Si no hay conexión, se borrará definitivamente al sincronizar.",
          style: TextStyle(color: Colors.white70, fontSize: 14),
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
            onPressed: () async {
              Navigator.pop(context);
              String msg = await vm.deleteItem(element.id);
              if (context.mounted) {
                _showSnackBar(context, msg, isError: msg.contains("Error"));
              }
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

  /// Muestra una notificación rápida en la parte inferior de la pantalla.
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade900 : Colors.green.shade900,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra un mensaje visual cuando no hay inversiones registradas.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: _headerColor,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            "Tu cartera está vacía",
            style: TextStyle(color: _textColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

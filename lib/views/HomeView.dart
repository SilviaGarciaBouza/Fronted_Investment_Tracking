import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/utils/app_strings.dart';
import 'package:investment_tracking/views/AddTransaction.dart';
import 'package:investment_tracking/views/total_view.dart';
import 'package:investment_tracking/views/TransactionDetailView.dart';
import 'package:investment_tracking/views/LoginView.dart';
import '../models/transaction.dart'; // Importante: ahora trabajamos con Transaction

class Homeview extends StatefulWidget {
  const Homeview({super.key});
  static const routeName = '/home';

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
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
    final lang = vm.currentLocale;
    final theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color textColor = vm.isDarkMode ? Colors.white : Colors.black;
    final Color headerColor = vm.isDarkMode
        ? Colors.grey.shade500
        : Colors.grey.shade700;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: Consumer<InvViewModel>(
            builder: (context, vm, child) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    vm.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    key: ValueKey(vm.isOnline),
                    color: vm.isOnline ? primaryColor : Colors.redAccent,
                  ),
                ),
                tooltip: vm.isOnline
                    ? AppStrings.get('tooltip_sync', lang)
                    : AppStrings.get('tooltip_no_sync', lang),
                onPressed: () {
                  if (vm.isOnline) {
                    vm.syncPendingData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(
                          child: Text(AppStrings.get('no_connection', lang)),
                        ),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
          title: Text(
            AppStrings.get('portfolio', lang),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                vm.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: primaryColor,
              ),
              tooltip: AppStrings.get('tooltip_theme', lang),
              onPressed: () => vm.toggleTheme(),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.language, color: primaryColor),
              tooltip: AppStrings.get('tooltip_lang', lang),
              onSelected: (code) => vm.setLanguage(code),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'es', child: Text("Español")),
                const PopupMenuItem(value: 'gl', child: Text("Galego")),
                const PopupMenuItem(value: 'en', child: Text("English")),
              ],
            ),
            IconButton(
              icon: Icon(Icons.leaderboard_outlined, color: primaryColor),
              tooltip: AppStrings.get('tooltip_stats', lang),
              onPressed: () =>
                  Navigator.pushNamed(context, TotalView.routeName),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: AppStrings.get('tooltip_logout', lang),
              onPressed: () async {
                await vm.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, LoginView.routeName);
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: primaryColor,
                  ),
                  labelColor: vm.isDarkMode ? Colors.black : Colors.white,
                  unselectedLabelColor: textColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tabs: [
                    Tab(text: AppStrings.get('tab_all', lang)),
                    Tab(text: AppStrings.get('tab_stocks', lang)),
                    Tab(text: AppStrings.get('tab_cryptos', lang)),
                    Tab(text: AppStrings.get('tab_currencies', lang)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: TabBarView(
                      children: [
                        _buildTransactionTab(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          null,
                        ),
                        _buildTransactionTab(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          'Acción',
                        ),
                        _buildTransactionTab(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          'Criptomoneda',
                        ),
                        _buildTransactionTab(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          'Divisa',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          tooltip: AppStrings.get('tooltip_add', lang),
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              Additem.routeName,
            );
            if (context.mounted) vm.fetchItems();

            if (result.runtimeType == String && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      result! as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: Icon(
            Icons.add,
            color: vm.isDarkMode ? Colors.black : Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTab(
    InvViewModel vm,
    String lang,
    Color primary,
    Color text,
    Color hColor,
    String? filter,
  ) {
    // 1. APLANADO DE TRANSACCIONES: Sacamos las transacciones de los items filtrados
    List<Transaction> transactions = [];
    for (var item in vm.itemList) {
      if (filter == null || item.categoryName == filter) {
        for (var tx in item.transactions) {
          transactions.add(tx);
        }
      }
    }

    // 2. ORDENACIÓN: La más reciente primero
    transactions.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return vm.isLoading && vm.itemList.isEmpty
        ? Center(child: CircularProgressIndicator(color: primary))
        : transactions.isEmpty
        ? _buildEmptyState(hColor, lang)
        : Column(
            children: [
              _buildHeader(lang, hColor),
              Divider(color: text.withOpacity(0.1)),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) => _buildTransactionRow(
                    transactions[index],
                    vm,
                    lang,
                    primary,
                    text,
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildHeader(String lang, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 15, right: 50, bottom: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              AppStrings.get('active', lang),
              style: _headerStyle(color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.get('date', lang),
              style: _headerStyle(color),
            ),
          ), // Etiqueta nueva
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.get('qty', lang),
              style: _headerStyle(color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.get('investment', lang),
              style: _headerStyle(color),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) =>
      TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold);

  Widget _buildTransactionRow(
    Transaction tx,
    InvViewModel vm,
    String lang,
    Color primary,
    Color text,
  ) {
    // Buscamos el nombre del activo al que pertenece esta transacción
    final parentItem = vm.itemList.firstWhereOrNull(
      (item) => item.transactions.contains(tx),
    );
    if (parentItem == null) {
      return SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: text.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 10, right: 0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailView(item: parentItem),
          ), // Reutilizamos tu vista de detalle
        ),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                parentItem.name,
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${tx.purchaseDate.day}/${tx.purchaseDate.month}",
                style: TextStyle(color: text, fontSize: 11),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                tx.stocks.toStringAsFixed(2),
                style: TextStyle(color: text, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${tx.invEur.toStringAsFixed(2)}€",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 18,
              ),
              onPressed: () => _confirmDeleteTransaction(
                tx,
                parentItem.name,
                vm,
                lang,
                text,
                parentItem.id!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(
    Transaction tx,
    String assetName,
    InvViewModel vm,
    String lang,
    Color textColor,
    int itemId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: vm.isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          "¿Borrar movimiento de $assetName?",
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.get('cancel', lang),
              style: TextStyle(color: textColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await vm.deleteTransaction(tx.id, tx.serverId, itemId);

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      child: Text(
                        AppStrings.get('transaction_deleted', vm.currentLocale),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text(
              AppStrings.get('delete', lang),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: color.withOpacity(0.5), size: 50),
          const SizedBox(height: 10),
          Text(
            AppStrings.get('empty', lang),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

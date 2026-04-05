// //AA Homeview.dart - Versión Final con Pestañas Estilo Imagen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/utils/app_strings.dart';
import 'package:investment_tracking/views/AddItem.dart';
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
          leading: IconButton(
            icon: Icon(
              vm.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: vm.isOnline ? primaryColor : Colors.redAccent,
            ),
            onPressed: () => vm.fetchItems(),
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
              onPressed: () => vm.toggleTheme(),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.language, color: primaryColor),
              onSelected: (code) => vm.setLanguage(code),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'es', child: Text("Español")),
                const PopupMenuItem(value: 'gl', child: Text("Galego")),
                const PopupMenuItem(value: 'en', child: Text("English")),
              ],
            ),
            IconButton(
              icon: Icon(Icons.leaderboard_outlined, color: primaryColor),
              onPressed: () =>
                  Navigator.pushNamed(context, TotalView.routeName),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await vm.logout();
                if (context.mounted)
                  Navigator.pushReplacementNamed(context, LoginView.routeName);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // //AA PESTAÑAS ESTILO BOTÓN (Imagen 2)
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

              // //AA CAJA CONTENEDORA CON BORDES (Imagen 2)
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
                        _buildTabContent(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          null,
                        ),
                        _buildTabContent(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          'Acción',
                        ),
                        _buildTabContent(
                          vm,
                          lang,
                          primaryColor,
                          textColor,
                          headerColor,
                          'Criptomoneda',
                        ),
                        _buildTabContent(
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
          onPressed: () async {
            await Navigator.pushNamed(context, Additem.routeName);
            if (context.mounted) vm.fetchItems();
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

  Widget _buildTabContent(
    InvViewModel vm,
    String lang,
    Color primary,
    Color text,
    Color hColor,
    String? filter,
  ) {
    // //AA Ahora 'categoryName' ya existe gracias al getter en Item.dart
    final list = filter == null
        ? vm.itemList
        : vm.itemList.where((i) => i.categoryName == filter).toList();

    return vm.isLoading && vm.itemList.isEmpty
        ? Center(child: CircularProgressIndicator(color: primary))
        : RefreshIndicator(
            color: primary,
            onRefresh: () => vm.fetchItems(),
            child: list.isEmpty
                ? _buildEmptyState(hColor, lang)
                : Column(
                    children: [
                      _buildHeader(lang, hColor),
                      Divider(color: text.withOpacity(0.1)),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: list.length,
                          itemBuilder: (context, index) => _buildItemRow(
                            list[index],
                            vm,
                            lang,
                            primary,
                            text,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
  }

  // ... (Sigue igual con _buildHeader, _buildItemRow, _confirmDelete y _buildEmptyState)

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
              AppStrings.get('qty', lang),
              style: _headerStyle(color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.get('value', lang),
              style: _headerStyle(color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              AppStrings.get('pnl', lang),
              style: _headerStyle(color),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) =>
      TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold);

  Widget _buildItemRow(
    Item element,
    InvViewModel vm,
    String lang,
    Color primary,
    Color text,
  ) {
    Color pnlColor = element.profitPercent >= 0 ? primary : Colors.redAccent;
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
            builder: (context) => TransactionDetailView(item: element),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                element.name,
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
                element.totalStocks.toStringAsFixed(2),
                style: TextStyle(color: text, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${element.currentValue.toStringAsFixed(2)}€",
                style: TextStyle(color: text, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${element.profitPercent.toStringAsFixed(2)}%",
                style: TextStyle(
                  color: pnlColor,
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
              onPressed: () => _confirmDelete(element, vm, lang, text),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    Item item,
    InvViewModel vm,
    String lang,
    Color textColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: vm.isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          "${AppStrings.get('delete_title', lang)} ${item.name}?",
          style: TextStyle(color: textColor),
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
            onPressed: () {
              vm.deleteItem(item.id!, item.serverId);
              Navigator.pop(context);
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
          Icon(
            Icons.account_balance_wallet_outlined,
            color: color.withOpacity(0.5),
            size: 50,
          ),
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

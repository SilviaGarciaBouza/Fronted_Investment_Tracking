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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            vm.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: vm.isOnline ? primaryColor : Colors.redAccent,
          ),
          tooltip: vm.isOnline
              ? AppStrings.get('sync_tooltip', lang)
              : AppStrings.get('offline_tooltip', lang),
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
            onPressed: () => Navigator.pushNamed(context, TotalView.routeName),
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
      body: vm.isLoading && vm.itemList.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: () => vm.fetchItems(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(lang, headerColor),
                    Divider(color: theme.dividerColor),
                    Expanded(
                      child: vm.itemList.isEmpty
                          ? _buildEmptyState(headerColor, lang)
                          : ListView.builder(
                              itemCount: vm.itemList.length,
                              itemBuilder: (context, index) => _buildItemRow(
                                vm.itemList[index],
                                vm,
                                lang,
                                primaryColor,
                                textColor,
                              ),
                            ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildHeader(String lang, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          const SizedBox(width: 35),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: text.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
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
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                element.totalStocks.toStringAsFixed(2),
                style: TextStyle(color: text, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${element.currentValue.toStringAsFixed(2)}€",
                style: TextStyle(color: text, fontSize: 13),
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
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color color, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: color, size: 50),
          const SizedBox(height: 10),
          Text(AppStrings.get('empty', lang), style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

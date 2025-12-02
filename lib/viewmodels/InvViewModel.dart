import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:investment_tracking/service/StockService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Item.dart';
import '../models/invModel.dart';
import '../models/Transaction.dart';

class Invviewmodel extends ChangeNotifier {
  InvModel invModel = InvModel();
  final StockService _stockService = StockService();
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  static const String _keyPortfolio = 'portfolioList';

  Invviewmodel() {
    loadPortfolio();
  }

  Future<void> savePortfolio() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = invModel.itemList.map((item) => item.toJson()).toList();
    final jsonString = json.encode(jsonList);

    await prefs.setString(_keyPortfolio, jsonString);
  }

  Future<void> loadPortfolio() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPortfolio);

    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List;

      invModel.itemList = jsonList
          .map((jsonItem) => Item.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

      await _refreshAllPrices();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshAllPrices() async {
    final updatedList = <Item>[];

    for (final item in invModel.itemList) {
      String symbol = item.name.toUpperCase();

      if (item.category == 'Criptomoneda' && !symbol.contains('USD')) {
        symbol = '${symbol}USD';
      }

      final currentPrice = await _stockService.getStockPrice(symbol);

      if (currentPrice <= 0.0) {
        updatedList.add(item);
        continue;
      }

      final totalStocks = item.stocks;
      final totalInvEur = item.invEur;
      final newCurrentValue = totalStocks * currentPrice;
      final newPnL = newCurrentValue - totalInvEur;
      final newPnLPercent = totalInvEur != 0.0
          ? (newPnL / totalInvEur) * 100
          : 0.0;

      final updatedItem = item.copyWith(
        valueEur: newCurrentValue,
        nRpL: newPnL,
        nRPlPercentaje: newPnLPercent,
      );
      updatedList.add(updatedItem);
    }

    invModel.itemList = updatedList;
    _updatePortfolioPercentages();
  }

  List<Item> getList() {
    return invModel.itemList;
  }

  double get totalInvestment {
    return invModel.itemList.fold(0.0, (sum, item) => sum + item.invEur);
  }

  double get totalCurrentValue {
    return invModel.itemList.fold(0.0, (sum, item) => sum + item.valueEur);
  }

  double get totalPnL {
    return totalCurrentValue - totalInvestment;
  }

  double get totalPnLPercent {
    if (totalInvestment == 0.0) return 0.0;
    return (totalPnL / totalInvestment) * 100;
  }

  Item? getItemByName(String name) {
    try {
      return invModel.itemList.firstWhere((e) => e.name == name);
    } catch (e) {
      return null;
    }
  }

  void _updatePortfolioPercentages() {
    final totalValue = totalCurrentValue;

    if (totalValue == 0.0) return;

    final updatedList = invModel.itemList.map((item) {
      final newPercent = (item.valueEur / totalValue) * 100;

      return item.copyWith(currentPercentaje: newPercent);
    }).toList();

    invModel.itemList = updatedList;
  }

  Future<void> addItem(Item newItemData) async {
    String symbol = newItemData.name.toUpperCase();

    if (symbol == 'BTC' || symbol == 'ETH' || symbol == 'SOL') {
      symbol = '${symbol}USD';
    }

    final currentPrice = await _stockService.getStockPrice(symbol);

    if (currentPrice <= 0.0) {
      return;
    }

    final newTransaction = Transaction(
      date: DateTime.now(),
      stocks: newItemData.stocks,
      purchasePrice: newItemData.sharePrize,
      invEur: newItemData.invEur,
    );

    final existingIndex = invModel.itemList.indexWhere((e) => e.name == symbol);

    Item updatedItem;

    if (existingIndex != -1) {
      final existingItem = invModel.itemList[existingIndex];

      final totalInvEur = existingItem.invEur + newTransaction.invEur;
      final totalStocks = existingItem.stocks + newTransaction.stocks;
      final newWAC = totalInvEur / totalStocks;

      final newCurrentValue = totalStocks * currentPrice;
      final newPnL = newCurrentValue - totalInvEur;
      final newPnLPercent = totalInvEur != 0.0
          ? (newPnL / totalInvEur) * 100
          : 0.0;

      updatedItem = existingItem.copyWith(
        sharePrize: newWAC,
        stocks: totalStocks,
        invEur: totalInvEur,
        valueEur: newCurrentValue,
        nRpL: newPnL,
        nRPlPercentaje: newPnLPercent,
        transactions: [...existingItem.transactions, newTransaction],
      );

      invModel.itemList[existingIndex] = updatedItem;
    } else {
      final invEurInitial = newTransaction.invEur;
      final valueEurInitial = newTransaction.stocks * currentPrice;

      updatedItem = Item(
        category: newItemData.category,
        name: symbol,
        idItem: invModel.itemList.length.toDouble() + 1,
        stocks: newTransaction.stocks,
        sharePrize: newTransaction.purchasePrice,
        invEur: invEurInitial,
        valueEur: valueEurInitial,
        nRpL: valueEurInitial - invEurInitial,
        nRPlPercentaje: invEurInitial != 0.0
            ? ((valueEurInitial - invEurInitial) / invEurInitial) * 100
            : 0.0,
        currentPercentaje: 0.0,
        transactions: [newTransaction],
      );

      invModel.addItem(updatedItem);
    }

    _updatePortfolioPercentages();
    notifyListeners();
    await savePortfolio();
  }

  @override
  Future<void> removeItem(String name) async {
    invModel.removeItem(name);
    _updatePortfolioPercentages();
    notifyListeners();
    await savePortfolio();
  }
}

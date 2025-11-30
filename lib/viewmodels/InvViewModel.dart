import 'package:flutter/material.dart';
import 'package:investment_tracking/service/StockService.dart';
import '../models/Item.dart';
import '../models/invModel.dart';

class Invviewmodel extends ChangeNotifier {
  InvModel invModel = InvModel();
  final StockService _stockService = StockService();

  List<Item> getList() {
    return invModel.itemList;
  }

  Future<void> addItem(Item item) async {
    final symbol = item.name.toUpperCase();

    final currentPrice = await _stockService.getStockPrice(symbol);

    if (currentPrice <= 0.0) {
      return;
    }

    final sharePrize = currentPrice;
    final invEur = item.stocks * sharePrize;
    final valueEur = invEur;
    const nRpL = 0.0;
    const nRPlPercentaje = 0.0;
    const currentPercentaje = 0.0;

    final itemWithValues = Item(
      category: item.category,
      name: symbol,
      idItem: item.idItem,
      stocks: item.stocks,
      sharePrize: sharePrize,
      invEur: invEur,
      valueEur: valueEur,
      nRpL: nRpL,
      nRPlPercentaje: nRPlPercentaje,
      currentPercentaje: currentPercentaje,
    );

    invModel.addItem(itemWithValues);
    notifyListeners();
  }

  void removeItem(String name) {
    invModel.removeItem(name);
    notifyListeners();
  }
}

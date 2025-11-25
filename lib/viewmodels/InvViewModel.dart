import 'package:flutter/material.dart';
import 'package:investment_tracking/models/Item.dart';
import 'package:investment_tracking/models/invModel.dart';

class Invviewmodel extends ChangeNotifier {
  InvModel invModel = InvModel();
  List<Item> getList() {
    return invModel.itemList;
  }

  void addItem(Item item) {
    invModel.addItem(item);
    notifyListeners();
  }

  void removeItem(String name) {
    invModel.removeItem(name);
    notifyListeners();
  }
}

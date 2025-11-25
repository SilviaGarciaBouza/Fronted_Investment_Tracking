
import 'package:flutter/material.dart';

import '../models/Item.dart';
import '../models/invModel.dart';

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

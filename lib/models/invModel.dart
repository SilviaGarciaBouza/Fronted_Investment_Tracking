import 'package:investment_tracking/models/Item.dart';


class InvModel {
  List<Item> itemList = [];
  void addItem(Item item) {
    itemList.add(item);
  }

  void removeItem(String name) {
    itemList.remove((e) => e.name == name);
  }
}

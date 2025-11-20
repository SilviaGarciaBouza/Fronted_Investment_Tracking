class Item {
  Item({
    required this.category,
    required this.currentPercentaje,
    required this.name,
    required this.idItem,
    required this.sharePrize,
    required this.stocks,
    required this.invEur,
    required this.valueEur,
    required this.nRpL,
    required this.nRPlPercentaje,
  });
  final String category;
  final String name;
  final double currentPercentaje;
  final double idItem;
  final double sharePrize;
  final double stocks;
  final double invEur;
  final double valueEur;
  final double nRpL;
  final double nRPlPercentaje;
}

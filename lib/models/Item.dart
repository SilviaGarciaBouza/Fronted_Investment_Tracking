import 'Transaction.dart';

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
    required this.transactions,
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
  final List<Transaction> transactions;

  Item copyWith({
    double? currentPercentaje,
    double? sharePrize,
    double? stocks,
    double? invEur,
    double? valueEur,
    double? nRpL,
    double? nRPlPercentaje,
    List<Transaction>? transactions,
  }) {
    return Item(
      category: category,
      name: name,
      idItem: idItem,
      currentPercentaje: currentPercentaje ?? this.currentPercentaje,
      sharePrize: sharePrize ?? this.sharePrize,
      stocks: stocks ?? this.stocks,
      invEur: invEur ?? this.invEur,
      valueEur: valueEur ?? this.valueEur,
      nRpL: nRpL ?? this.nRpL,
      nRPlPercentaje: nRPlPercentaje ?? this.nRPlPercentaje,
      transactions: transactions ?? this.transactions,
    );
  }
}

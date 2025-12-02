class Transaction {
  Transaction({
    required this.date,
    required this.stocks,
    required this.purchasePrice,
    required this.invEur,
  });

  final DateTime date;
  final double stocks;
  final double purchasePrice;
  final double invEur;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: DateTime.parse(json['date'] as String),
      stocks: (json['stocks'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      invEur: (json['invEur'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'stocks': stocks,
      'purchasePrice': purchasePrice,
      'invEur': invEur,
    };
  }
}

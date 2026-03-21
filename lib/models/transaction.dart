class Transaction {
  final int id;
  final double stocks;
  final double purchasePrice;
  final double invEur;
  final DateTime purchaseDate;

  Transaction({
    required this.id,
    required this.stocks,
    required this.purchasePrice,
    required this.invEur,
    required this.purchaseDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      stocks: (json['stocks'] ?? 0.0).toDouble(),
      purchasePrice: (json['purchasePrice'] ?? 0.0).toDouble(),
      invEur: (json['invEur'] ?? 0.0).toDouble(),
      purchaseDate: DateTime.parse(
        json['purchaseDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stocks': stocks,
    'purchasePrice': purchasePrice,
    'invEur': invEur,
    'purchaseDate': purchaseDate.toIso8601String(),
  };
}

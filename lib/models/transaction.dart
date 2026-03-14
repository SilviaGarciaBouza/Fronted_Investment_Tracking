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
      stocks: json['stocks'].toDouble(),
      purchasePrice: json['purchasePrice'].toDouble(),
      invEur: json['invEur'].toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
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

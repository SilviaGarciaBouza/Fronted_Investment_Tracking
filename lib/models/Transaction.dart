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
  final double invEur; // stocks * purchasePrice
}

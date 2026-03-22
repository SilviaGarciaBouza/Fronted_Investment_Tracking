/// Representa una operación individual de compra o movimiento financiero.
///
/// Contiene datos sobre la cantidad de acciones, precio y fecha.
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

  /// Mapea los datos del servidor a un objeto [Transaction].
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

  /// Convierte la transacción para ser enviada al servidor o guardada.
  Map<String, dynamic> toJson() => {
    'id': id,
    'stocks': stocks,
    'purchasePrice': purchasePrice,
    'invEur': invEur,
    'purchaseDate': purchaseDate.toIso8601String(),
  };
}

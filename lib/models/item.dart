import 'category.dart';
import 'transaction.dart';

class Item {
  final int id;
  final String name;
  final Category category;
  final List<Transaction> transactions;
  final double currentPrice;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.transactions,
    required this.currentPrice,
  });

  // Cálculos automáticos para la UI
  // Inversión total (lo que pagaste en su día)
  double get invEur => transactions.fold(0, (sum, tx) => sum + tx.invEur);

  // Cantidad de activos que tienes
  double get stocks => transactions.fold(0, (sum, tx) => sum + tx.stocks);

  // P&L %: Ahora es una comparativa real entre mercado e inversión
  double get nRPlPercentaje =>
      invEur == 0 ? 0 : ((valueEur - invEur) / invEur) * 100;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      category: Category.fromJson(json['category']),
      currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }
  // VALOR ACTUAL:  Stocks x Precio de Mercado Real

  double get valueEur => stocks * currentPrice;
}

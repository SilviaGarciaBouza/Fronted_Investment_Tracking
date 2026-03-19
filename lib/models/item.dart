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

  // Inversión total
  double get invEur => transactions.fold(0, (sum, tx) => sum + tx.invEur);

  // Cantidad de activos
  double get stocks => transactions.fold(0, (sum, tx) => sum + tx.stocks);

  // P&L
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

  factory Item.fromLocalMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      category: Category(id: 0, name: map['category_name'] ?? 'Sin categoría'),
      currentPrice: (map['current_price'] ?? 0.0).toDouble(),
      transactions: [],
    );
  }

  Map<String, dynamic> toLocalMap(int userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category_name': category.name,
      'current_price': currentPrice,
      'stocks': stocks,
      'pnl_percent': nRPlPercentaje,
    };
  }
}

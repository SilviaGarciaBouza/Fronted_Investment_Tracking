import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/transaction.dart';

/// Representa un activo financiero completo (Item) en la cartera.
///
/// Incluye su categoría, lista de transacciones y cálculos de rentabilidad.
class Item {
  final int id;
  final int? serverId;
  final String name;
  final Category category;
  final List<Transaction> transactions;
  final double currentPrice;
  final bool isSynced;
  final bool isDeleted;

  Item({
    required this.id,
    this.serverId,
    required this.name,
    required this.category,
    required this.transactions,
    required this.currentPrice,
    this.isSynced = true,
    this.isDeleted = false,
  });

  /// Calcula el total invertido en euros sumando las transacciones.
  double get invEur => transactions.fold(0, (sum, tx) => sum + tx.invEur);

  /// Suma la cantidad total de acciones o participaciones.
  double get stocks => transactions.fold(0, (sum, tx) => sum + tx.stocks);

  /// Valor actual de la inversión basado en el precio de mercado.
  double get valueEur => stocks * currentPrice;

  /// Calcula el porcentaje de pérdidas o ganancias no realizadas.
  double get nRPlPercentaje =>
      invEur == 0 ? 0 : ((valueEur - invEur) / invEur) * 100;

  /// Constructor para crear un [Item] desde la respuesta de la API.
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      // Forzamos que el ID se trate como int siempre
      id: int.parse(json['id'].toString()),
      serverId: int.parse(json['id'].toString()),
      name: json['name'] ?? 'Sin nombre',
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : Category(id: 1, name: 'General'),
      currentPrice: (json['currentPrice'] ?? json['current_price'] ?? 0.0)
          .toDouble(),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
                .map((t) => Transaction.fromJson(t))
                .toList()
          : [],
      isSynced: true,
    );
  }

  /// Mapea los datos provenientes de la base de datos local (SQLite).
  factory Item.fromLocalMap(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> txMaps,
  ) {
    return Item(
      id: map['id'],
      serverId: map['server_id'],
      name: map['name'],
      category: Category(id: 0, name: map['category_name'] ?? 'Inversión'),
      currentPrice: (map['current_price'] ?? 0.0).toDouble(),
      isSynced: map['is_synced'] == 1,
      isDeleted: map['is_deleted'] == 1,
      transactions: txMaps
          .map(
            (tx) => Transaction(
              id: tx['id'],
              stocks: (tx['stocks'] ?? 0.0).toDouble(),
              purchasePrice: (tx['purchase_price'] ?? 0.0).toDouble(),
              invEur: (tx['inv_eur'] ?? 0.0).toDouble(),
              purchaseDate: DateTime.parse(tx['purchase_date']),
            ),
          )
          .toList(),
    );
  }

  /// Prepara el objeto para ser persistido en la base de datos local.
  Map<String, dynamic> toLocalMap(int userId) {
    return {
      'id': id,
      'server_id': serverId,
      'user_id': userId,
      'name': name,
      'category_name': category.name,
      'current_price': currentPrice,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}

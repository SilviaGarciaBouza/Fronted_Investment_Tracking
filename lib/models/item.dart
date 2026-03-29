import 'category.dart';
import 'transaction.dart';

/// Representa un activo (ej: Apple, Bitcoin) con su historial y rentabilidad.
class Item {
  // Autoincrement en SQLite
  final int? id;
  // ID en MariaDB
  final int? serverId;
  final String name;
  final Category category;
  final List<Transaction> transactions;
  final double currentPrice;
  final bool isSynced;
  // Flag para "borrado pendiente" cuando no hay conexion.

  final bool isDeleted;

  Item({
    this.id,
    this.serverId,
    required this.name,
    required this.category,
    required this.transactions,
    required this.currentPrice,
    this.isSynced = true,
    this.isDeleted = false,
  });

  // -Lógica de Negocio para el ViewModel
  double get totalStocks => transactions.fold(0, (sum, tx) => sum + tx.stocks);
  double get totalInvEur => transactions.fold(0, (sum, tx) => sum + tx.invEur);
  double get currentValue => totalStocks * currentPrice;
  double get profitEur => currentValue - totalInvEur;
  double get profitPercent =>
      totalInvEur == 0 ? 0 : (profitEur / totalInvEur) * 100;

  /// Crea un Item desde el DTO del Backend.
  factory Item.fromJson(Map<String, dynamic> json) => Item(
    serverId: int.parse(json['id'].toString()),
    name: json['name'] ?? '',
    category: json['category'] != null
        ? Category.fromJson(json['category'])
        : Category(id: 0, name: 'Inversión'),
    currentPrice: (json['currentPrice'] ?? 0.0).toDouble(),
    transactions:
        (json['transactions'] as List?)
            ?.map((t) => Transaction.fromJson(t))
            .toList() ??
        [],
    isSynced: true,
  );

  /// Mapea datos desde SQLite.
  factory Item.fromLocalMap(
    Map<String, dynamic> map,
    List<Transaction> txList,
  ) => Item(
    id: map['id'],
    serverId: map['server_id'],
    name: map['name'],
    category: Category(id: map['category_id'] ?? 0, name: 'Cargando...'),
    currentPrice: (map['current_price'] ?? 0.0).toDouble(),
    isSynced: map['is_synced'] == 1,
    isDeleted: map['is_deleted'] == 1,
    transactions: txList,
  );

  /// Exporta a mapa para SQLite.
  Map<String, dynamic> toLocalMap(int userId) => {
    'id': id,
    'server_id': serverId,
    'user_id': userId,
    'name': name,
    'category_id': category.id,
    'current_price': currentPrice,
    'is_synced': isSynced ? 1 : 0,
    'is_deleted': isDeleted ? 1 : 0,
  };
}

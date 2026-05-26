import 'category.dart';
import 'transaction.dart';

/// Representa un activo (ej: Apple, Bitcoin) con su historial y rentabilidad.
class Item {
  /// ID autoincremental en la base de datos local SQLite.
  final int? id;

  /// ID único guardado en la base de datos remota MariaDB.
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

  /// Obtiene la cantidad total de acciones o tokens acumulados mediante las transacciones.
  double get totalStocks => transactions.fold(0, (sum, tx) => sum + tx.stocks);

  /// Obtiene el total de dinero invertido en euros en este activo.
  double get totalInvEur => transactions.fold(0, (sum, tx) => sum + tx.invEur);

  /// Calcula el valor actual de mercado de la posición total.
  double get currentValue => totalStocks * currentPrice;

  /// Calcula la ganancia o pérdida neta acumulada en euros.
  double get profitEur => currentValue - totalInvEur;

  /// Calcula el porcentaje de rendimiento actual respecto al dinero invertido.
  double get profitPercent =>
      totalInvEur == 0 ? 0 : (profitEur / totalInvEur) * 100;

  /// Crea un Item desde el DTO del Backend.
  factory Item.fromJson(Map<String, dynamic> json) => Item(
    serverId: int.parse(json['id'].toString()),
    name: json['name'] ?? '',
    category: json['category'] != null
        ? Category.fromJson(json['category'])
        : Category(id: 0, name: 'Inversión'),
    currentPrice: (json['currentPrice'] ?? json['current_price'] ?? 0.0)
        .toDouble(),
    transactions:
        (json['transactions'] as List?)
            ?.map((t) => Transaction.fromJson(t))
            .toList() ??
        [],
    isSynced: true,
  );

  /// Mapea datos desde un registro de SQLite junto con su lista de transacciones.
  factory Item.fromLocalMap(
    Map<String, dynamic> map,
    List<Transaction> txList,
  ) => Item(
    id: map['id'],
    serverId: map['server_id'],
    name: map['name'],
    category: Category(
      id: map['category_id'] ?? 0,
      name: map['category_name'] ?? 'Inversión',
    ),
    currentPrice: (map['current_price'] ?? 0.0).toDouble(),
    isSynced: map['is_synced'] == 1,
    isDeleted: map['is_deleted'] == 1,
    transactions: txList,
  );

  /// Exporta los campos del activo a un mapa compatible con SQLite de forma local.
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

  /// Devuelve el nombre legible de la categoría asignada.
  String get categoryName => category.name;
}

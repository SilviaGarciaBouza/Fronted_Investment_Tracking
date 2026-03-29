/// Representa un movimiento de compra dentro de un [Item].
///
/// Gestiona la sincronización individual para permitir ráfagas de subida
/// cuando se recupera la conexión.
class Transaction {
  final int? id; // ID local en SQLite (autoincrement)
  final int? serverId; // ID real en MariaDB
  final double stocks;
  final double purchasePrice;
  final double invEur;
  final DateTime purchaseDate;
  final bool isSynced;

  Transaction({
    this.id,
    this.serverId,
    required this.stocks,
    required this.purchasePrice,
    required this.invEur,
    required this.purchaseDate,
    this.isSynced = true,
  });

  /// Factory para DTOs del backend.
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    serverId: int.parse(json['id'].toString()),
    stocks: (json['stocks'] ?? 0.0).toDouble(),
    purchasePrice: (json['purchasePrice'] ?? 0.0).toDouble(),
    invEur: (json['invEur'] ?? 0.0).toDouble(),
    purchaseDate: DateTime.parse(json['purchaseDate']),
    isSynced: true,
  );

  /// Mapea el resultado de una consulta de SQLite (Mapa) a un objeto Transaction.
  factory Transaction.fromLocalMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    serverId: map['server_id'],
    stocks: (map['stocks'] as num).toDouble(),
    purchasePrice: (map['purchase_price'] as num).toDouble(),
    invEur: (map['inv_eur'] as num).toDouble(),
    purchaseDate: DateTime.parse(map['purchase_date']),
    isSynced: map['is_synced'] == 1,
  );

  /// Prepara los datos para insertar en SQLite local.
  Map<String, dynamic> toLocalMap(int localItemId) => {
    'id': id,
    'server_id': serverId,
    // Relación con el ID local del activo
    'item_id': localItemId,
    'stocks': stocks,
    'purchase_price': purchasePrice,
    'inv_eur': invEur,
    'purchase_date': purchaseDate.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };
}

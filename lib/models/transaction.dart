/// Representa un movimiento de compra dentro de un [Item].
///
/// Gestiona la sincronización individual para permitir ráfagas de subida
/// cuando se recupera la conexión.
class Transaction {
  // ID local en SQLite (autoincrement)
  int? id;
  final int? serverId;
  // ID  en MariadB
  final double stocks;
  final double purchasePrice;
  final double invEur;
  final DateTime purchaseDate;
  final bool isSynced;
  final bool isDeleted;
  final int? itemId;

  Transaction({
    this.id,
    this.serverId,
    required this.stocks,
    required this.purchasePrice,
    required this.invEur,
    required this.purchaseDate,
    this.isSynced = true,
    this.isDeleted = false,
    this.itemId,
  });

  /// Factory para DTOs del backend.
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    serverId: json['id'] != null ? int.parse(json['id'].toString()) : null,
    stocks: (json['stocks'] ?? json['amount'] ?? 0.0).toDouble(),
    purchasePrice: (json['purchasePrice'] ?? json['purchase_price'] ?? 0.0)
        .toDouble(),
    invEur: (json['invEur'] ?? json['inv_eur'] ?? 0.0).toDouble(),
    purchaseDate: DateTime.parse(
      json['purchaseDate'] ??
          json['purchase_date'] ??
          DateTime.now().toIso8601String(),
    ),
    isSynced: true,
  );

  /// Mapea el resultado de una consulta de SQLite (Mapa) a un objeto Transaction.
  factory Transaction.fromLocalMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    serverId: map['server_id'],
    stocks: (map['stocks'] as num? ?? 0.0).toDouble(),
    purchasePrice: (map['purchase_price'] as num? ?? 0.0).toDouble(),
    invEur: (map['inv_eur'] as num? ?? 0.0).toDouble(),
    purchaseDate: DateTime.parse(map['purchase_date']),
    isSynced: map['is_synced'] == 1,
    itemId: map['item_id'],
    isDeleted: map['is_deleted'] == 1,
  );

  /// Prepara los datos para insertar en SQLite local.
  Map<String, dynamic> toLocalMap(int localItemId) => {
    'id': id,
    'server_id': serverId,
    'item_id': localItemId,
    'stocks': stocks,
    'purchase_price': purchasePrice,
    'inv_eur': invEur,
    'purchase_date': purchaseDate.toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
    'is_deleted': isDeleted ? 1 : 0,
  };
}

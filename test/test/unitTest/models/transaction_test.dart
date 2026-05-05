import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/models/transaction.dart';

void main() {
  group('Transaction: serialización y mapeo', () {
    test('fromJson parsea correctamente una fecha ISO8601', () {
      final json = {
        'id': 1,
        'stocks': 1.5,
        'purchase_price': 100.0,
        'inv_eur': 150.0,
        'purchase_date': '2026-04-05T12:00:00.000Z',
      };

      final tx = Transaction.fromJson(json);

      expect(tx.purchaseDate.year, 2026);
      expect(tx.purchaseDate.month, 4);
    });

    test('toLocalMap convierte is_synced a entero para SQLite', () {
      final tx = Transaction(
        stocks: 1.0,
        purchasePrice: 50.0,
        invEur: 50.0,
        purchaseDate: DateTime.now(),
        isSynced: true,
      );

      final map = tx.toLocalMap(10);

      expect(map['is_synced'], 1);
      expect(map['item_id'], 10);
    });

    test('fromLocalMap reconstruye el objeto desde SQLite', () {
      final map = {
        'id': 10,
        'server_id': 20,
        'item_id': 5,
        'stocks': 3.0,
        'purchase_price': 150.0,
        'inv_eur': 450.0,
        'purchase_date': '2026-03-15T00:00:00.000',
        'is_synced': 1,
        'is_deleted': 0,
      };

      final tx = Transaction.fromLocalMap(map);

      expect(tx.id, 10);
      expect(tx.serverId, 20);
      expect(tx.stocks, 3.0);
      expect(tx.invEur, 450.0);
      expect(tx.isSynced, true);
      expect(tx.isDeleted, false);
      expect(tx.purchaseDate.month, 3);
    });
  });
}

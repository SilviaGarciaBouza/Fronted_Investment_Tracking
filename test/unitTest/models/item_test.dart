import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/models/transaction.dart';

void main() {
  final testCategory = Category(id: 1, name: 'Criptomoneda');
  final date = DateTime.now();

  group('Item: financial calculations', () {
    test('calculates totals correctly with multiple transactions', () {
      final item = Item(
        name: 'Bitcoin',
        category: testCategory,
        currentPrice: 60000.0,
        transactions: [
          Transaction(
            stocks: 0.5,
            purchasePrice: 40000.0,
            invEur: 20000.0,
            purchaseDate: date,
          ),
          Transaction(
            stocks: 0.2,
            purchasePrice: 50000.0,
            invEur: 10000.0,
            purchaseDate: date,
          ),
        ],
      );

      expect(item.totalStocks, 0.7);
      expect(item.totalInvEur, 30000.0);
      expect(item.currentValue, 42000.0);
      expect(item.profitEur, 12000.0);
    });

    test('calculates profit percentage correctly', () {
      final item = Item(
        name: 'Ethereum',
        category: testCategory,
        currentPrice: 4000.0,
        transactions: [
          Transaction(
            stocks: 1.0,
            purchasePrice: 2000.0,
            invEur: 2000.0,
            purchaseDate: date,
          ),
        ],
      );

      expect(item.profitPercent, 100.0);
    });

    test('returns 0% profit when there are no transactions (avoids division by zero)', () {
      final item = Item(
        name: 'Test',
        category: testCategory,
        currentPrice: 100.0,
        transactions: [],
      );

      expect(item.profitPercent, 0.0);
    });
  });

  group('Item: serialization and mapping', () {
    test('fromLocalMap reconstructs the object from SQLite', () {
      final localMap = {
        'id': 1,
        'server_id': 101,
        'name': 'Apple',
        'category_id': 2,
        'category_name': 'Acción',
        'current_price': 150.0,
        'is_synced': 1,
        'is_deleted': 0,
      };

      final item = Item.fromLocalMap(localMap, []);

      expect(item.name, 'Apple');
      expect(item.category.name, 'Acción');
      expect(item.isSynced, true);
    });

    test('fromJson parses the backend DTO with nested transactions', () {
      final json = {
        'id': '5',
        'name': 'Tesla',
        'currentPrice': 250.0,
        'category': {'id': '2', 'name': 'Acción'},
        'transactions': [
          {
            'id': '1',
            'stocks': 2.0,
            'purchasePrice': 200.0,
            'invEur': 400.0,
            'purchaseDate': '2026-01-01T00:00:00.000Z',
          },
        ],
      };

      final item = Item.fromJson(json);

      expect(item.name, 'Tesla');
      expect(item.serverId, 5);
      expect(item.category.name, 'Acción');
      expect(item.transactions.length, 1);
      expect(item.isSynced, true);
    });

    test('toLocalMap serializes booleans as integers for SQLite', () {
      final item = Item(
        name: 'Gold',
        category: Category(id: 3, name: 'Materias primas'),
        transactions: [],
        currentPrice: 1800.0,
        isSynced: false,
        isDeleted: true,
      );

      final map = item.toLocalMap(7);

      expect(map['user_id'], 7);
      expect(map['name'], 'Gold');
      expect(map['category_id'], 3);
      expect(map['is_synced'], 0);
      expect(map['is_deleted'], 1);
    });
  });
}

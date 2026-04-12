import 'package:flutter_test/flutter_test.dart';
import 'package:investment_tracking/models/item.dart';
import 'package:investment_tracking/models/category.dart';
import 'package:investment_tracking/models/transaction.dart';
import 'package:investment_tracking/models/user.dart';

void main() {
  /// Grupo de pruebas para el modelo Item.
  /// Valida la lógica de cálculos financieros y agregación de transacciones.
  group('Pruebas del Modelo Item', () {
    final testCategory = Category(id: 1, name: 'Criptomoneda');
    final date = DateTime.now();

    /// Verifica que las propiedades calculadas (stocks e inversión total) coincidan con el historial.
    test('Debe calcular correctamente los totales de una inversión', () {
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

    /// Verifica que la rentabilidad porcentual se calcule correctamente sobre la base invertida.
    test('Debe calcular el porcentaje de beneficio correctamente', () {
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

    /// Valida la seguridad del modelo ante divisiones por cero en activos sin transacciones.
    test(
      'Debe devolver 0% de beneficio si la inversión inicial es 0 (Evitar división por cero)',
      () {
        final item = Item(
          name: 'Test',
          category: testCategory,
          currentPrice: 100.0,
          transactions: [],
        );

        expect(item.profitPercent, 0.0);
      },
    );
  });

  /// Grupo de pruebas para el mapeo de datos.
  /// Valida la comunicación entre el formato JSON de la API y el formato LocalMap de SQLite.
  group('Pruebas de Mapeo (JSON y LocalMap)', () {
    /// Asegura que los datos del usuario y el token JWT se extraigan correctamente de la respuesta del servidor.
    test('User.fromJson debe mapear correctamente el Token y los datos', () {
      final json = {
        'token': 'jwt_secret_token',
        'user': {'id': 10, 'username': 'admin', 'email': 'admin@test.com'},
      };

      final user = User.fromJson(json);

      expect(user.id, 10);
      expect(user.username, 'admin');
      expect(user.token, 'jwt_secret_token');
    });

    /// Valida la reconstrucción de objetos desde los datos persistidos en la base de datos local.
    test('Item.fromLocalMap debe reconstruir el objeto desde SQLite', () {
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
  });

  /// Grupo de pruebas para el modelo Transaction.
  /// Valida el manejo de tiempos y la compatibilidad con el esquema de SQLite.
  group('Pruebas del Modelo Transaction', () {
    /// Verifica que las fechas enviadas por el backend sean interpretadas correctamente por Dart.
    test('Debe parsear correctamente una fecha ISO8601', () {
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

    /// Valida la conversión de booleanos a enteros requerida por la persistencia local.
    test(
      'Debe convertir correctamente a mapa para SQLite (is_synced a int)',
      () {
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
      },
    );
  });

  /// Grupo de pruebas para el modelo User.
  /// Valida la flexibilidad del constructor ante diferentes estructuras de respuesta.
  group('Pruebas del Modelo User', () {
    /// Asegura la compatibilidad con respuestas anidadas de Spring Boot y respuestas planas de caché.
    test('Debe manejar el JSON tanto si viene anidado como plano', () {
      final jsonAnidado = {
        'token': 'abc',
        'user': {'id': 1, 'username': 'lucia', 'email': 'l@test.com'},
      };

      final user1 = User.fromJson(jsonAnidado);
      expect(user1.username, 'lucia');
      expect(user1.token, 'abc');

      final jsonPlano = {
        'id': 2,
        'username': 'pepe',
        'email': 'p@test.com',
        'token': 'xyz',
      };

      final user2 = User.fromJson(jsonPlano);
      expect(user2.username, 'pepe');
    });
  });

  /// Grupo de pruebas para el modelo Category.
  /// Valida la robustez ante la recepción de tipos de datos inconsistentes.
  group('Pruebas del Modelo Category', () {
    /// Garantiza que los identificadores de texto se conviertan a tipos numéricos para la base de datos.
    test('Debe convertir ID de String a int si es necesario', () {
      final json = {'id': "5", 'name': 'Divisa'};

      final cat = Category.fromJson(json);

      expect(cat.id, 5);
      expect(cat.id, isA<int>());
    });
  });
}

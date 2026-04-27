import '../dao/transaction_dao.dart';
import '../models/transaction.dart';
import '../service/api_service.dart';

class TransactionRepository {
  final ApiService _apiService = ApiService();
  final TransactionDao _transactionDao = TransactionDao();

  /// Obtiene todas las transacciones para el Home (usando el JOIN del DAO)
  Future<List<Transaction>> getHomeTransactions(
    int userId,
    String token,
  ) async {
    try {
      final List<Map<String, dynamic>> maps = await _transactionDao
          .getAllTransactionsForHome(userId);

      return maps.map((m) => Transaction.fromLocalMap(m)).toList();
    } catch (e) {
      final List<Map<String, dynamic>> maps = await _transactionDao
          .getAllTransactionsForHome(userId);
      return maps.map((m) => Transaction.fromLocalMap(m)).toList();
    }
  }

  /// Borra una transacción individual (la papelera del Home)
  Future<bool> deleteTransaction(
    int localId,
    int? serverId,
    String token,
  ) async {
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/transactions/$serverId',
          token: token,
        );
        if (success) {
          await _transactionDao.deletePhysically(localId);
          return true;
        }
      } else {
        await _transactionDao.deletePhysically(localId);
        return true;
      }
      return false;
    } catch (e) {
      // Si no hay red, marcamos para borrar luego
      await _transactionDao.markForDeletion(localId);
      return false;
    }
  }

  /// Crea una nueva transacción para un ITEM existente (Botón +)
  Future<void> createTransaction(
    int itemId,
    Transaction tx,
    String token,
  ) async {
    try {
      final response = await _apiService.post('/transactions', {
        "itemId": itemId,
        "amount": tx.stocks,
        "purchasePrice": tx.purchasePrice,
        "date": tx.purchaseDate.toIso8601String(),
      }, token: token);

      if (response != null) {
        // Guardar en SQLite como sincronizado
        // await _transactionDao.saveTransaction(Transaction.fromJson(response));
      }
    } catch (e) {
      // Guardar en SQLite como pendiente (is_synced = 0)
    }
  }
}

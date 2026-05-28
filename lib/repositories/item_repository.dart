import 'package:flutter/foundation.dart' hide Category;
import 'package:investment_tracking/dao/caegory_dao.dart';
import 'package:investment_tracking/dao/transaction_dao.dart';
import 'package:investment_tracking/exceptions/Server_unavailable_exception.dart';
import 'package:investment_tracking/exceptions/Unauthorized_exception.dart';
import 'package:investment_tracking/models/transaction.dart';
import 'package:investment_tracking/utils/network_error_utils.dart';
import '../models/category.dart';
import '../dao/item_dao.dart';
import '../models/item.dart';
import '../service/api_service.dart';

/// Repositorio unificado para la gestión de activos financieros (Items).
/// Coordina la estrategia de persistencia híbrida: decide cuándo consumir y enviar
/// datos a la base de datos remota (MariaDB mediante [ApiService]) y cuándo
/// almacenar o consultar en la base de datos local ([ItemDao] con SQLite).
class ItemRepository {
  final ApiService _apiService = ApiService();
  final ItemDao _itemDao = ItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final TransactionDao _transactionDao = TransactionDao();

  /// Sincroniza y obtiene los activos de un usuario desde el servidor.
  /// Intenta descargar los datos más recientes mediante la API, los vuelca en la
  /// base de datos local para asegurar la disponibilidad offline, y finalmente
  /// retorna los registros actualizados desde SQLite.
  /// * Lanza [UnauthorizedException] si las credenciales o el token no son válidos.
  /// * Lanza [ServerUnavailableException] si hay problemas de red o el servidor no responde.
  Future<List<Item>> fetchUserItems(int userId, String token) async {
    try {
      final data = await _apiService.get('/items/user/$userId', token: token);
      final List<Item> remoteItems = (data as List)
          .map((j) => Item.fromJson(j))
          .toList();
      await _itemDao.saveItems(remoteItems, userId);
      return await _itemDao.getItems(userId);
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      if (!isServerUnavailableError(e)) rethrow;
      debugPrint("Modo Offline: No se pudo refrescar desde el servidor.");
      throw ServerUnavailableException();
    }
  }

  /// Recupera de forma directa los activos almacenados en la base de datos local.
  /// Útil para cargas rápidas de la interfaz o cuando el dispositivo se encuentra sin red.
  Future<List<Item>> getLocalItems(int userId) async {
    return await _itemDao.getItems(userId);
  }

  /// Guarda un nuevo activo financiero en el sistema de manera síncrona/asíncrona.
  /// Intenta crear el activo en el servidor. Si tiene éxito, guarda la respuesta
  /// (con su ID remoto asignado) en SQLite. Si el servidor no está disponible,
  /// lo registra en local con una bandera de pendiente de sincronización.
  /// * Lanza [UnauthorizedException] si el token expiró o es inválido.
  /// * Lanza [ServerUnavailableException] si se guarda en modo desconectado (Offline).
  Future<void> saveItem(
    Item item,
    double stocks,
    double price,
    int userId,
    String token,
  ) async {
    try {
      final response = await _apiService.post('/items', {
        "name": item.name,
        "userId": userId,
        "categoryId": item.category.id,
        "initialStocks": stocks,
        "initialPrice": price,
      }, token: token);

      if (response != null) {
        final serverItem = Item.fromJson(response);
        await _itemDao.saveItems([serverItem], userId);
      }
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      if (!isServerUnavailableError(e)) rethrow;
      await _itemDao.saveItemOffline(item, stocks, price, userId);
      throw ServerUnavailableException();
    }
  }

  /// Elimina un activo financiero del sistema.
  /// Si el activo cuenta con un identificador del servidor ([serverId]), intenta
  /// borrarlo de la base de datos remota antes de removerlo de SQLite.
  /// Si el servidor está inaccesible, realiza un borrado lógico marcándolo para
  /// eliminación posterior (`markForDeletion`).
  Future<bool> deleteItem(int localId, int? serverId, String token) async {
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/items/$serverId',
          token: token,
        );
        if (success) {
          await _itemDao.deleteItemPhysically(localId);
          return true;
        }
      } else {
        await _itemDao.deleteItemPhysically(localId);
        return true;
      }
      return false;
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      if (!isServerUnavailableError(e)) rethrow;
      await _itemDao.markForDeletion(localId);
      throw ServerUnavailableException();
    }
  }

  /// Elimina una transacción específica y evalúa si se debe limpiar su activo asociado.
  /// Realiza la baja en el servidor (si [serverId] existe) o de forma local. Si al eliminar
  /// la transacción el activo se queda sin ningún movimiento asociado, el método procede
  /// a eliminar físicamente o marcar para borrado el activo padre ([itemId]).
  Future<bool> deleteTransaction(
    int localId,
    int? serverId,
    String token,
    int itemId,
  ) async {
    int numTransactionItemsTotal;
    int numTransactionItems;
    try {
      if (serverId != null) {
        final success = await _apiService.delete(
          '/transactions/$serverId',
          token: token,
        );

        if (success) {
          await _transactionDao.deletePhysically(localId);
          numTransactionItemsTotal = await _transactionDao
              .getTransactionItemsCountTotal(itemId);

          if (numTransactionItemsTotal == 0) {
            await _itemDao.deleteItemPhysically(itemId);
          }
          return true;
        } else {
          await _transactionDao.markForDeletion(localId);
          numTransactionItems = await _transactionDao.getTransactionItemsCount(
            itemId,
          );
          if (numTransactionItems == 0) {
            await _itemDao.markForDeletion(itemId);
          }
          return true;
        }
      } else {
        await _transactionDao.markForDeletion(localId);
        numTransactionItems = await _transactionDao.getTransactionItemsCount(
          itemId,
        );
        if (numTransactionItems == 0) {
          await _itemDao.markForDeletion(itemId);
        }
        return true;
      }
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      if (!isServerUnavailableError(e)) rethrow;
      await _transactionDao.markForDeletion(localId);
      numTransactionItems = await _transactionDao.getTransactionItemsCount(
        itemId,
      );
      if (numTransactionItems == 0) {
        await _itemDao.markForDeletion(itemId);
      }
      throw ServerUnavailableException();
    }
  }

  /// Registra una nueva transacción para un activo, creándolo localmente si no existe.
  /// Busca el activo por nombre. Si no lo encuentra, inicializa uno nuevo en SQLite
  /// marcado como no sincronizado (`isSynced: false`). Posteriormente guarda la transacción
  /// e inicia un proceso automático de sincronización en segundo plano ([syncPendingData]).
  Future<void> saveTransaction(
    String name,
    double stocks,
    double price,
    int categoryId,
    int userId,
    String token,
  ) async {
    var item = await _itemDao.getItembyName(name, userId);
    int itemId;
    if (item == null) {
      item = Item(
        name: name,
        category:
            await _categoryDao.getCategoryById(categoryId) ??
            Category(id: 0, name: ""),
        transactions: [],
        isSynced: false,
        currentPrice: 0.0,
      );
      itemId = await _itemDao.createItem(item, userId);
    } else {
      if (item.id == null) throw StateError("Item exist but has not locad id");
      itemId = item.id!;
    }

    final transaction = Transaction(
      itemId: itemId,
      stocks: stocks,
      purchasePrice: price,
      invEur: stocks * price,
      purchaseDate: DateTime.now(),
      isSynced: false,
    );
    await _transactionDao.saveTransaction(transaction, itemId!);
    await syncPendingData(userId, token);
  }

  /// Sincroniza de forma masiva los datos pendientes de SQLite hacia el servidor central.
  Future<void> syncPendingData(int userId, String token) async {
    bool serverError = false;

    for (var item in await _itemDao.getPendingDeletions(userId)) {
      try {
        if (item.serverId != null) {
          final success = await _apiService.delete(
            '/items/${item.serverId}',
            token: token,
          );
          if (success) await _itemDao.deleteItemPhysically(item.id!);
        }
      } catch (e) {
        debugPrint("Error borrando item: $e");
        if (isServerUnavailableError(e)) serverError = true;
      }
    }

    for (var t in await _transactionDao.getPendingToDelete()) {
      try {
        if (t.serverId != null) {
          final success = await _apiService.delete(
            '/transactions/${t.serverId}',
            token: token,
          );
          if (success) await _transactionDao.deletePhysically(t.id!);
        }
      } catch (e) {
        debugPrint("Error borrando transacción: $e");
        if (isServerUnavailableError(e)) serverError = true;
      }
    }

    for (var item in await _itemDao.getUnsyncedItems(userId)) {
      try {
        if (item.serverId == null) {
          final success = await _apiService.post('/items', {
            'name': item.name,
            'categoryId': item.category.id,
            'transactions': [],
            'currentPrice': 0.0,
            'userId': userId,
            'initialStocks': 0,
          }, token: token);
          if (success != null && success['id'] != null) {
            await _itemDao.markAsSynced(item.id!, success['id']);
          }
        }
      } catch (e) {
        debugPrint("Error subiendo item: $e");
        if (isServerUnavailableError(e)) serverError = true;
      }
    }

    for (var transaction in await _transactionDao.getUnsyncTransactions()) {
      try {
        final parentItem = await _itemDao.getItemById(transaction.itemId!);
        if (parentItem != null && parentItem.serverId != null) {
          final response = await _apiService
              .post('/transactions/item/${parentItem.serverId}', {
                'itemId': parentItem.serverId,
                'stocks': transaction.stocks,
                'purchasePrice': transaction.purchasePrice,
                'invEur': transaction.invEur,
                'purchaseDate': transaction.purchaseDate.toIso8601String(),
              }, token: token);
          if (response != null && response['id'] != null) {
            await _transactionDao.markAsSynced(transaction.id!, response['id']);
          }
        }
      } catch (e) {
        debugPrint("Error subiendo trans: $e");
        if (isServerUnavailableError(e)) serverError = true;
      }
    }

    if (serverError) throw ServerUnavailableException();
  }
}

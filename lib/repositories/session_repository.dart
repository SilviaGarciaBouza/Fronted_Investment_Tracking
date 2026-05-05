import 'package:investment_tracking/service/storage_service.dart';

class SessionRepository {
  final StorageService _storageService = StorageService();
  static const _userKey = 'current_user_id';

  Future<void> saveUserId(int userId) async {
    await _storageService.write(_userKey, userId.toString());
  }

  Future<int?> getUserId() async {
    final jsonString = await _storageService.read(_userKey);
    if (jsonString == null) return null;
    return int.parse(jsonString);
  }

  Future<void> clearUserId() async {
    await _storageService.delete(_userKey);
  }
}

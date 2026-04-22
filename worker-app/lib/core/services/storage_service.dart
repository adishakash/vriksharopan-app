import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late Box _box;
  static late Box _offlineBox;

  static const String _tokenKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userKey = 'worker_data';
  static const String _fcmKey = 'fcm_token';

  static Future<void> init() async {
    _box = await Hive.openBox('worker_storage');
    _offlineBox = await Hive.openBox('offline_queue');
  }

  static Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _box.put(_tokenKey, access);
    await _box.put(_refreshKey, refresh);
  }

  static String? getAccessToken() => _box.get(_tokenKey);
  static String? getRefreshToken() => _box.get(_refreshKey);
  static Future<void> clearTokens() async {
    await _box.delete(_tokenKey);
    await _box.delete(_refreshKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _box.put(_userKey, user);
  static Map<dynamic, dynamic>? getUser() => _box.get(_userKey);
  static Future<void> clearUser() => _box.delete(_userKey);

  static Future<void> saveFcmToken(String t) => _box.put(_fcmKey, t);
  static String? getFcmToken() => _box.get(_fcmKey);

  // Offline queue
  static Future<void> queueMaintenanceLog(Map<String, dynamic> log) async {
    final List existing = _offlineBox.get('maintenance_queue', defaultValue: []);
    existing.add(log);
    await _offlineBox.put('maintenance_queue', existing);
  }

  static List getMaintenanceQueue() =>
      _offlineBox.get('maintenance_queue', defaultValue: []);

  static Future<void> clearMaintenanceQueue() =>
      _offlineBox.delete('maintenance_queue');

  static Future<void> clearAll() async {
    await _box.clear();
    await _offlineBox.clear();
  }
}

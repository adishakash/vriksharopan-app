import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late Box _box;

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _fcmTokenKey = 'fcm_token';

  static Future<void> init() async {
    _box = await Hive.openBox('app_storage');
  }

  // Tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_tokenKey, accessToken);
    await _box.put(_refreshTokenKey, refreshToken);
  }

  static String? getAccessToken() => _box.get(_tokenKey);
  static String? getRefreshToken() => _box.get(_refreshTokenKey);

  static Future<void> clearTokens() async {
    await _box.delete(_tokenKey);
    await _box.delete(_refreshTokenKey);
  }

  // User
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _box.put(_userKey, user);
  }

  static Map<dynamic, dynamic>? getUser() => _box.get(_userKey);

  static Future<void> clearUser() async => _box.delete(_userKey);

  // FCM token
  static Future<void> saveFcmToken(String token) async =>
      _box.put(_fcmTokenKey, token);

  static String? getFcmToken() => _box.get(_fcmTokenKey);

  // Full clear (logout)
  static Future<void> clearAll() async => _box.clear();

  // Generic
  static Future<void> set(String key, dynamic value) async =>
      _box.put(key, value);

  static dynamic get(String key, {dynamic defaultValue}) =>
      _box.get(key, defaultValue: defaultValue);
}

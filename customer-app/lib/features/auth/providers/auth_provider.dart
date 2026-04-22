import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  AuthProvider() {
    _checkStoredSession();
  }

  void _checkStoredSession() {
    final token = StorageService.getAccessToken();
    final userData = StorageService.getUser();
    if (token != null && userData != null) {
      _user = UserModel.fromJson(userData);
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String mobile,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    String? referralCode,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      apiService.init();
      final res = await apiService.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'mobile': mobile,
        'role': 'customer',
        'address': address,
        'city': city,
        'state': state,
        'pin_code': pinCode,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      });

      final data = res.data['data'];
      await _saveSession(data);
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Registration failed.';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      apiService.init();
      final res = await apiService.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
        'role': 'customer',
      });

      final data = res.data['data'];
      await _saveSession(data);
      return true;
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data['message'] ?? 'Login failed. Check your credentials.';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession(Map<dynamic, dynamic> data) async {
    await StorageService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final userMap = Map<String, dynamic>.from(data['user'] as Map);
    await StorageService.saveUser(userMap);
    _user = UserModel.fromJson(userMap);
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await apiService.post(ApiConstants.logout, data: {
        'refreshToken': StorageService.getRefreshToken(),
      });
    } catch (_) {}

    await StorageService.clearAll();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiService.post(ApiConstants.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      await logout();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Password change failed.';
      notifyListeners();
      return false;
    }
  }

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    StorageService.saveUser(updatedUser.toJson());
    notifyListeners();
  }
}

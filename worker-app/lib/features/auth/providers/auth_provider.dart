import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/worker_model.dart';
import '../../../core/constants/api_constants.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  WorkerModel? _worker;
  String? _error;

  AuthState get state => _state;
  WorkerModel? get worker => _worker;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  AuthProvider() {
    _checkStoredSession();
    apiService.init();
  }

  void _checkStoredSession() {
    final token = StorageService.getAccessToken();
    final userData = StorageService.getUser();
    if (token != null && userData != null) {
      _worker = WorkerModel.fromJson(Map<String, dynamic>.from(userData));
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await apiService.post(ApiConstants.login,
          data: {'email': email, 'password': password});
      final data = res.data['data'];
      final worker = WorkerModel.fromJson(data['user']);
      if (worker.role != 'worker') {
        _error = 'Access denied. Workers only.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
      await StorageService.saveTokens(
        access: data['accessToken'],
        refresh: data['refreshToken'],
      );
      await StorageService.saveUser(worker.toJson());
      _worker = worker;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await apiService.post(ApiConstants.logout);
    } catch (_) {}
    await StorageService.clearAll();
    _worker = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void updateWorker(WorkerModel w) {
    _worker = w;
    StorageService.saveUser(w.toJson());
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      return e.response?.data?['message'] ?? 'Network error. Try again.';
    }
    return 'Something went wrong. Try again.';
  }
}

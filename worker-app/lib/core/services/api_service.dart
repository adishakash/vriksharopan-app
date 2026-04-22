import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  late Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = StorageService.getAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final ok = await _refresh();
          if (ok) {
            e.requestOptions.headers['Authorization'] =
                'Bearer ${StorageService.getAccessToken()}';
            try {
              return handler.resolve(await _dio.fetch(e.requestOptions));
            } catch (_) {}
          }
        }
        handler.next(e);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(requestBody: true));
    }
  }

  Future<bool> _refresh() async {
    final rt = StorageService.getRefreshToken();
    if (rt == null) return false;
    try {
      final res = await Dio().post(
          '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
          data: {'refreshToken': rt});
      await StorageService.saveTokens(
        access: res.data['data']['accessToken'],
        refresh: res.data['data']['refreshToken'],
      );
      return true;
    } catch (_) {
      await StorageService.clearAll();
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);
  Future<Response> upload(String path, FormData form) =>
      _dio.post(path, data: form,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}));
}

final apiService = ApiService();

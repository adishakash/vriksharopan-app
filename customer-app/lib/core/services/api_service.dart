import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor: attach token + handle 401 refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry original request with new token
              final opts = e.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${StorageService.getAccessToken()}';
              try {
                final res = await _dio.fetch(opts);
                return handler.resolve(res);
              } catch (_) {}
            }
          }
          handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = StorageService.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data['data'];
      await StorageService.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
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

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
  }) =>
      _dio.post(path,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}));
}

final apiService = ApiService();

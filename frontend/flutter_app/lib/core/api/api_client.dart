import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import '../storage/secure_storage.dart';

/// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

/// HTTP API Client with authentication handling
class ApiClient {
  final Ref _ref;
  late final Dio _dio;
  
  ApiClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - try to refresh token
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              final options = error.requestOptions;
              final token = await SecureStorage.getAccessToken();
              options.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (e) {
                handler.reject(error);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConfig.refresh,
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await SecureStorage.saveTokens(
          accessToken: response.data['access_token'],
          refreshToken: response.data['refresh_token'],
        );
        return true;
      }
    } catch (e) {
      await SecureStorage.clearTokens();
    }
    return false;
  }
  
  // HTTP Methods
  
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return _dio.put(path, data: data);
  }
  
  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
  
  /// Upload file with multipart form data (cross-platform: web, mobile, desktop)
  /// Uses bytes instead of dart:io File for web compatibility
  Future<Response> uploadFileBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
      if (fields != null) ...fields,
    });
    
    return _dio.post(
      path,
      data: formData,
      options: Options(
        receiveTimeout: ApiConfig.uploadTimeout,
        sendTimeout: ApiConfig.uploadTimeout,
      ),
    );
  }
}


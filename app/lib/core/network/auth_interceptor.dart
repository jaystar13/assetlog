import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;

  // 토큰 갱신 중복 방지
  Completer<void>? _refreshCompleter;

  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // /auth/refresh 자체가 401이면 더 이상 재시도하지 않음
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }

    try {
      await _tryRefreshToken();

      // 새 토큰으로 원래 요청 재시도
      final token = await _tokenStorage.getAccessToken();
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException {
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }
  }

  Future<void> _tryRefreshToken() async {
    // 이미 갱신 중이면 완료될 때까지 대기
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) throw DioException(requestOptions: RequestOptions());

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {
          'Authorization': 'Bearer $refreshToken',
        }),
      );

      final accessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}

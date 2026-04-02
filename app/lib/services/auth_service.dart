import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// POST /auth/refresh — 토큰 갱신 (Refresh Token Rotation)
  Future<({String accessToken, String refreshToken})> refresh(
    String refreshToken,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {
          'Authorization': 'Bearer $refreshToken',
        }),
      );
      return (
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/logout — 로그아웃
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /auth/me — 내 프로필 조회
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

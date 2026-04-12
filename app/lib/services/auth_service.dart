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
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final data = _unwrap(response);
      return (
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/exchange — 일회용 코드 → 토큰 교환
  Future<Map<String, dynamic>> exchangeAuthCode(String code) async {
    try {
      final response = await _dio.post('/auth/exchange', data: {'code': code});
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/logout — 로그아웃
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /auth/me — 내 프로필 조회
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH /users/me — 프로필 수정
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatar,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: {'name': ?name, 'avatar': ?avatar},
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /users/me — 회원 탈퇴
  Future<void> withdraw() async {
    try {
      await _dio.delete('/users/me');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /users/me/goal — 목표 조회
  Future<Map<String, dynamic>?> getGoal() async {
    try {
      final response = await _dio.get('/users/me/goal');
      final body = response.data;
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as Map<String, dynamic>?;
      }
      return body as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /users/me/goal — 목표 설정/수정
  Future<Map<String, dynamic>> upsertGoal({
    required int startAmount,
    required int targetAmount,
    required String deadline,
  }) async {
    try {
      final response = await _dio.put(
        '/users/me/goal',
        data: {
          'startAmount': startAmount,
          'targetAmount': targetAmount,
          'deadline': deadline,
        },
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 백엔드 응답 래퍼 {data, meta}에서 data 추출
  Map<String, dynamic> _unwrap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }
}

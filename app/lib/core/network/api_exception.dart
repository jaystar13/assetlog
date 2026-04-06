import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: '서버 응답 시간이 초과되었습니다.');
      case DioExceptionType.connectionError:
        return const ApiException(message: '네트워크에 연결할 수 없습니다.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final rawMessage =
            data is Map<String, dynamic> ? data['message'] : null;
        final serverMessage = rawMessage is String
            ? rawMessage
            : rawMessage is List
                ? rawMessage.join(', ')
                : null;
        return ApiException(
          statusCode: statusCode,
          message: serverMessage ?? '요청 처리 중 오류가 발생했습니다.',
        );
      default:
        return const ApiException(message: '알 수 없는 오류가 발생했습니다.');
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

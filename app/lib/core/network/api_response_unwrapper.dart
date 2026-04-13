import 'package:dio/dio.dart';

/// 백엔드 응답 래퍼 `{data, meta}`에서 실제 데이터를 추출하는 공통 mixin.
///
/// 모든 API 서비스에서 동일한 응답 포맷을 사용하므로,
/// 이 mixin을 통해 중복 코드를 제거합니다.
mixin ApiResponseUnwrapper {
  /// 단일 객체 응답에서 data 추출
  Map<String, dynamic> unwrap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }

  /// 단일 객체 응답에서 data 추출 (nullable — data가 null일 수 있는 경우)
  Map<String, dynamic>? unwrapOrNull(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as Map<String, dynamic>?;
    }
    return body as Map<String, dynamic>?;
  }

  /// 리스트 응답에서 data 추출
  List<dynamic> unwrapList(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as List<dynamic>;
    }
    return body as List<dynamic>;
  }
}

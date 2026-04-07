import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';

class AssetService {
  final Dio _dio;

  AssetService(this._dio);

  /// GET /assets?status=active|closed|all&month=YYYY-MM
  Future<List<Map<String, dynamic>>> getAssets({String status = 'active', String? month}) async {
    try {
      final response = await _dio.get(
        '/assets',
        queryParameters: {
          'status': status,
          if (month != null) 'month': month,
        },
      );
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /assets
  Future<Map<String, dynamic>> createAsset({
    required String categoryId,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/assets',
        data: {'categoryId': categoryId, 'name': name},
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH /assets/:id
  Future<Map<String, dynamic>> updateAsset(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/assets/$id', data: data);
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /assets/:id
  Future<void> deleteAsset(String id) async {
    try {
      await _dio.delete('/assets/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH /assets/:id/close
  Future<Map<String, dynamic>> closeAsset(String id) async {
    try {
      final response = await _dio.patch('/assets/$id/close');
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /assets/:id/history
  Future<List<Map<String, dynamic>>> getHistory(String assetId) async {
    try {
      final response = await _dio.get('/assets/$assetId/history');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /assets/:id/history/:month
  Future<Map<String, dynamic>> upsertHistory({
    required String assetId,
    required String month,
    required int value,
  }) async {
    try {
      final response = await _dio.put(
        '/assets/$assetId/history/$month',
        data: {'value': value},
      );
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _unwrap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }

  List<dynamic> _unwrapList(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'] as List<dynamic>;
    }
    return body as List<dynamic>;
  }
}

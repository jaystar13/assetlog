import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';

class SharedAccessService {
  final Dio _dio;

  SharedAccessService(this._dio);

  // ─── Invitations ─────────────────────────────────────────

  Future<Map<String, dynamic>> createInvitation({
    required String toEmail,
    required String cashflowPermission,
    required Map<String, String> assetPermissions,
    String? message,
  }) async {
    try {
      final response = await _dio.post('/invitations', data: {
        'toEmail': toEmail,
        'cashflowPermission': cashflowPermission,
        'assetPermissions': assetPermissions,
        if (message != null) 'message': message,
      });
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSentInvitations() async {
    try {
      final response = await _dio.get('/invitations/sent');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getReceivedInvitations() async {
    try {
      final response = await _dio.get('/invitations/received');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String id) async {
    try {
      final response = await _dio.post('/invitations/$id/accept');
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> declineInvitation(String id) async {
    try {
      await _dio.post('/invitations/$id/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> cancelInvitation(String id) async {
    try {
      await _dio.delete('/invitations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Shared Access ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOwnedShares() async {
    try {
      final response = await _dio.get('/shared-access');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSharedWithMe() async {
    try {
      final response = await _dio.get('/shared-access/shared-with-me');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updatePermissions(
    String id, {
    String? cashflowPermission,
    Map<String, String>? assetPermissions,
  }) async {
    try {
      final response = await _dio.patch('/shared-access/$id', data: {
        if (cashflowPermission != null) 'cashflowPermission': cashflowPermission,
        if (assetPermissions != null) 'assetPermissions': assetPermissions,
      });
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSharedAssets(String accessId, {String? month}) async {
    try {
      final response = await _dio.get('/shared-access/$accessId/assets', queryParameters: {
        if (month != null) 'month': month,
      });
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSharedTransactions(String accessId, {String? month}) async {
    try {
      final response = await _dio.get('/shared-access/$accessId/transactions', queryParameters: {
        if (month != null) 'month': month,
      });
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeShare(String id) async {
    try {
      await _dio.delete('/shared-access/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

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

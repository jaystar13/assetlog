import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';

class ShareGroupService {
  final Dio _dio;

  ShareGroupService(this._dio);

  // ─── 그룹 CRUD ─────────────────────────────────

  Future<Map<String, dynamic>> createGroup(String name) async {
    try {
      final response = await _dio.post('/share-groups', data: {'name': name});
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    try {
      final response = await _dio.get('/share-groups');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final response = await _dio.get('/share-groups/$groupId');
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _dio.delete('/share-groups/$groupId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── 멤버 관리 ─────────────────────────────────

  Future<Map<String, dynamic>> inviteToGroup(
    String groupId, {
    required String toEmail,
    String? message,
  }) async {
    try {
      final response = await _dio.post('/share-groups/$groupId/invite', data: {
        'toEmail': toEmail,
        if (message != null) 'message': message,
      });
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> removeMember(String groupId, String memberId) async {
    try {
      await _dio.delete('/share-groups/$groupId/members/$memberId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.post('/share-groups/$groupId/leave');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── 초대 수신 ─────────────────────────────────

  Future<List<Map<String, dynamic>>> getReceivedInvitations() async {
    try {
      final response = await _dio.get('/share-groups/invitations/received');
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    try {
      final response = await _dio.post('/share-groups/invitations/$invitationId/accept');
      return _unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _dio.post('/share-groups/invitations/$invitationId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── 항목 공유 ─────────────────────────────────

  Future<void> shareItems(String groupId, List<Map<String, dynamic>> items) async {
    try {
      await _dio.post('/share-groups/$groupId/items', data: {'items': items});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> unshareItem(String groupId, String sharedItemId) async {
    try {
      await _dio.delete('/share-groups/$groupId/items/$sharedItemId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── 공유 데이터 조회 ──────────────────────────

  Future<List<Map<String, dynamic>>> getGroupTransactions(String groupId, {String? month}) async {
    try {
      final response = await _dio.get('/share-groups/$groupId/transactions', queryParameters: {
        if (month != null) 'month': month,
      });
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAssets(String groupId, {String? month}) async {
    try {
      final response = await _dio.get('/share-groups/$groupId/assets', queryParameters: {
        if (month != null) 'month': month,
      });
      return _unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Helpers ───────────────────────────────────

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

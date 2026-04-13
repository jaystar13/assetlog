import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../core/network/api_response_unwrapper.dart';

class ShareGroupService with ApiResponseUnwrapper {
  final Dio _dio;

  ShareGroupService(this._dio);

  // ─── 그룹 CRUD ─────────────────────────────────

  Future<Map<String, dynamic>> createGroup(String name) async {
    try {
      final response = await _dio.post('/share-groups', data: {'name': name});
      return unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    try {
      final response = await _dio.get('/share-groups');
      return unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final response = await _dio.get('/share-groups/$groupId');
      return unwrap(response);
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
    String? nickname,
    String? color,
    String? message,
  }) async {
    try {
      final response = await _dio.post(
        '/share-groups/$groupId/invite',
        data: {
          'toEmail': toEmail,
          'nickname': ?nickname,
          'color': ?color,
          'message': ?message,
        },
      );
      return unwrap(response);
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
      return unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    try {
      final response = await _dio.post(
        '/share-groups/invitations/$invitationId/accept',
      );
      return unwrap(response);
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

  Future<void> shareItems(
    String groupId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      await _dio.post('/share-groups/$groupId/items', data: {'items': items});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<String>> getItemSharedGroups(
    String itemType,
    String itemId,
  ) async {
    try {
      final response = await _dio.get(
        '/share-groups/item-groups',
        queryParameters: {'itemType': itemType, 'itemId': itemId},
      );
      return unwrapList(response).cast<String>();
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

  // ─── 활동 이력 ─────────────────────────────────

  Future<List<Map<String, dynamic>>> getActivityLogs(String groupId) async {
    try {
      final response = await _dio.get('/share-groups/$groupId/activity');
      return unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── 공유 데이터 조회 ──────────────────────────

  Future<List<Map<String, dynamic>>> getGroupTransactions(
    String groupId, {
    String? month,
  }) async {
    try {
      final response = await _dio.get(
        '/share-groups/$groupId/transactions',
        queryParameters: {'month': ?month},
      );
      return unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getGroupAssets(
    String groupId, {
    String? month,
  }) async {
    try {
      final response = await _dio.get(
        '/share-groups/$groupId/assets',
        queryParameters: {'month': ?month},
      );
      return unwrapList(response).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

}

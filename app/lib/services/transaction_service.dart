import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../core/network/api_response_unwrapper.dart';
import '../models/transaction.dart';

class TransactionService with ApiResponseUnwrapper {
  final Dio _dio;

  TransactionService(this._dio);

  /// GET /transactions?month=YYYY-MM&type=income|expense
  Future<List<Transaction>> getTransactions({
    required String month,
    String? type,
  }) async {
    try {
      final response = await _dio.get(
        '/transactions',
        queryParameters: {'month': month, 'type': ?type},
      );
      final data = unwrapList(response);
      return data
          .map((e) => Transaction.fromMap(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /transactions — upsert (same month+category+subCategory merges).
  Future<Transaction> createTransaction({
    required String type,
    required String targetMonth,
    required String category,
    required String subCategory,
    required int amount,
    String? note,
    List<String>? shareGroupIds,
  }) async {
    try {
      final response = await _dio.post(
        '/transactions',
        data: {
          'type': type,
          'targetMonth': targetMonth,
          'category': category,
          'subCategory': subCategory,
          'amount': amount,
          'note': ?note,
          'shareGroupIds': ?shareGroupIds,
        },
      );
      return Transaction.fromMap(unwrap(response));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH /transactions/:id — 금액/비고만 수정 가능.
  Future<Transaction> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch('/transactions/$id', data: data);
      return Transaction.fromMap(unwrap(response));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /transactions/:id
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /transactions/batch-delete — 일괄 삭제
  Future<int> batchDeleteTransactions(List<String> ids) async {
    try {
      final response = await _dio.post(
        '/transactions/batch-delete',
        data: {'ids': ids},
      );
      final data = unwrap(response);
      return data['deleted'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

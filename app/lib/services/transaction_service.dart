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

  /// POST /transactions
  Future<Transaction> createTransaction({
    required String type,
    required String name,
    required int amount,
    required String date,
    required String category,
    required String subCategory,
    String? paymentMethod,
    String? targetMonth,
    List<String>? shareGroupIds,
  }) async {
    try {
      final response = await _dio.post(
        '/transactions',
        data: {
          'type': type,
          'name': name,
          'amount': amount,
          'date': date,
          'category': category,
          'subCategory': subCategory,
          'paymentMethod': ?paymentMethod,
          'targetMonth': ?targetMonth,
          'shareGroupIds': ?shareGroupIds,
        },
      );
      return Transaction.fromMap(unwrap(response));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PATCH /transactions/:id
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

  /// POST /import/transactions — 카드 명세서 일괄 업로드
  Future<Map<String, dynamic>> importTransactions({
    required String cardCompany,
    required String targetMonth,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'cardCompany': cardCompany,
        'targetMonth': targetMonth,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post('/import/transactions', data: formData);
      return unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

}

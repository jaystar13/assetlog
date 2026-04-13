import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../core/network/api_response_unwrapper.dart';
import '../models/daily_quote.dart';

class QuoteService with ApiResponseUnwrapper {
  final Dio _dio;

  QuoteService(this._dio);

  /// GET /quotes/daily — 오늘의 명언
  Future<DailyQuote?> getDailyQuote() async {
    try {
      final response = await _dio.get('/quotes/daily');
      final data = unwrap(response);
      return DailyQuote.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

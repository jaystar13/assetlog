import 'package:flutter/foundation.dart';

abstract class Env {
  static String get apiBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;
    return kReleaseMode
        ? 'https://assetlog-production.up.railway.app'
        : 'http://localhost:3000';
  }
}

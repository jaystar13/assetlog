import 'package:flutter/foundation.dart';

/// 앱 전역에서 사용하는 사용자 설정 (추후 SharedPreferences/DB 연동)
class UserPreferences extends ChangeNotifier {
  static final UserPreferences _instance = UserPreferences._();
  factory UserPreferences() => _instance;
  UserPreferences._();

  String _subtitle = '나의 자산을 한눈에';

  String get subtitle => _subtitle;

  void setSubtitle(String value) {
    if (value.trim().isNotEmpty && value != _subtitle) {
      _subtitle = value.trim();
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences extends ChangeNotifier {
  static final UserPreferences _instance = UserPreferences._();
  factory UserPreferences() => _instance;
  UserPreferences._();

  static const _subtitleKey = 'user_subtitle';
  static const _defaultSubtitle = '나의 자산을 한눈에';

  String _subtitle = _defaultSubtitle;
  bool _initialized = false;

  String get subtitle => _subtitle;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _subtitle = prefs.getString(_subtitleKey) ?? _defaultSubtitle;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setSubtitle(String value) async {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed != _subtitle) {
      _subtitle = trimmed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subtitleKey, trimmed);
      notifyListeners();
    }
  }
}

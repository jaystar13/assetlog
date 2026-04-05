import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../providers.dart';
import '../storage/token_storage.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final TokenStorage _tokenStorage;
  late final AuthService _authService;

  @override
  AuthState build() {
    _tokenStorage = ref.watch(tokenStorageProvider);
    _authService = ref.watch(authServiceProvider);
    return const AuthState.unknown();
  }

  Future<void> checkAuthStatus() async {
    final hasTokens = await _tokenStorage.hasTokens();
    if (!hasTokens) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _authService.getMe();
      state = AuthState.authenticated(user);
    } catch (_) {
      await _tokenStorage.clearTokens();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> handleAuthCallback({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await checkAuthStatus();
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _authService.logout(refreshToken);
      }
    } catch (_) {
      // 로그아웃 API 실패해도 로컬 토큰은 삭제
    } finally {
      await _tokenStorage.clearTokens();
      state = const AuthState.unauthenticated();
    }
  }
}

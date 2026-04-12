import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'design_system/theme/app_theme.dart';
import 'router/app_router.dart';

class AssetLogApp extends ConsumerStatefulWidget {
  const AssetLogApp({super.key});

  @override
  ConsumerState<AssetLogApp> createState() => _AssetLogAppState();
}

class _AssetLogAppState extends ConsumerState<AssetLogApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _initDeepLinks();
  }

  Future<void> _initAuth() async {
    await ref.read(authNotifierProvider.notifier).checkAuthStatus();
  }

  Future<void> _initDeepLinks() async {
    final deepLinkService = ref.read(deepLinkServiceProvider);

    // 콜드 스타트: 앱이 딥링크로 열린 경우
    final initialUri = await deepLinkService.getInitialLink();
    if (initialUri != null) _handleDeepLink(initialUri);

    // 앱 실행 중 딥링크 수신
    _linkSubscription = deepLinkService.onLink.listen(_handleDeepLink);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.host != 'auth' || uri.path != '/callback') return;

    final code = uri.queryParameters['code'];
    if (code == null) return;

    try {
      final tokens = await ref.read(authServiceProvider).exchangeAuthCode(code);
      final accessToken = tokens['accessToken'] as String?;
      final refreshToken = tokens['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await ref.read(authNotifierProvider.notifier).handleAuthCallback(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
      }
    } catch (_) {
      // 코드 교환 실패 시 무시 (만료된 코드 등)
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Asset Log',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

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

  void _handleDeepLink(Uri uri) {
    if (uri.host != 'auth' || uri.path != '/callback') return;

    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];

    if (accessToken != null && refreshToken != null) {
      ref.read(authNotifierProvider.notifier).handleAuthCallback(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/env.dart';
import '../core/providers.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/radius.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _launchOAuth(String provider) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: '${Env.apiBaseUrl}/auth/$provider',
        callbackUrlScheme: 'assetlog',
      );

      final uri = Uri.parse(result);

      // 탈퇴 후 재가입 불가 안내
      final error = uri.queryParameters['error'];
      if (error == 'withdrawn' && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
            title: Text('가입할 수 없는 계정', style: AppTypography.heading3),
            content: Text(
              '이전에 탈퇴한 계정입니다.\n탈퇴 후 재가입은 불가합니다.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('확인', style: TextStyle(color: AppColors.emerald600)),
              ),
            ],
          ),
        );
        return;
      }

      // 일회용 코드로 토큰 교환
      final code = uri.queryParameters['code'];
      if (code != null) {
        final tokens = await ref.read(authServiceProvider).exchangeAuthCode(code);
        final accessToken = tokens['accessToken'] as String?;
        final refreshToken = tokens['refreshToken'] as String?;
        final restored = tokens['restored'] as bool? ?? false;

        if (accessToken != null && refreshToken != null) {
          await ref.read(authNotifierProvider.notifier).handleAuthCallback(
                accessToken: accessToken,
                refreshToken: refreshToken,
              );

          if (restored && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('탈퇴가 철회되었습니다. 다시 오신 것을 환영합니다!'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } on PlatformException catch (e) {
      // 사용자가 인앱 브라우저를 닫은 경우는 무시
      if (e.code != 'CANCELED' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),
              _buildLogo(),
              const Spacer(flex: 2),
              _buildSocialButtons(),
              const SizedBox(height: AppSpacing.xl),
              _buildFooter(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: SvgPicture.asset(
            'assets/icons/app_logo.svg',
            width: 72,
            height: 72,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('AssetLog', style: AppTypography.heading1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '나의 자산을 한눈에',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialLoginButton(
          label: 'Google로 시작하기',
          backgroundColor: Colors.white,
          textColor: AppColors.gray800,
          borderColor: AppColors.gray200,
          icon: const _GoogleIcon(),
          isLoading: _isLoading,
          onPressed: () => _launchOAuth('google'),
        ),
        const SizedBox(height: AppSpacing.md),
        _SocialLoginButton(
          label: '카카오로 시작하기',
          backgroundColor: Colors.white,
          textColor: AppColors.gray800,
          borderColor: AppColors.gray200,
          icon: const _KakaoIcon(),
          isLoading: _isLoading,
          onPressed: () => _launchOAuth('kakao'),
        ),
        const SizedBox(height: AppSpacing.md),
        _SocialLoginButton(
          label: '네이버로 시작하기',
          backgroundColor: Colors.white,
          textColor: AppColors.gray800,
          borderColor: AppColors.gray200,
          icon: const _NaverIcon(),
          isLoading: _isLoading,
          onPressed: () => _launchOAuth('naver'),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '로그인 시 서비스 이용약관 및 개인정보처리방침에 동의합니다.',
      style: AppTypography.caption.copyWith(color: AppColors.gray400),
      textAlign: TextAlign.center,
    );
  }
}

// ─── Social Login Button ────────────────────────────────────

class _SocialLoginButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.icon,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.label.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Brand Icons (placeholder — replace with actual SVG/PNG assets) ───

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/icons/google_logo.svg', width: 20, height: 20);
  }
}

class _KakaoIcon extends StatelessWidget {
  const _KakaoIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF191919));
  }
}

class _NaverIcon extends StatelessWidget {
  const _NaverIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/icons/naver_icon.svg', width: 20, height: 20);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];

      if (accessToken != null && refreshToken != null) {
        await ref.read(authNotifierProvider.notifier).handleAuthCallback(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
      }
    } catch (_) {
      // 사용자가 인앱 브라우저를 닫은 경우
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.emerald500,
            borderRadius: AppRadius.lgAll,
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 36,
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
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF191919),
          icon: const _KakaoIcon(),
          isLoading: _isLoading,
          onPressed: () => _launchOAuth('kakao'),
        ),
        const SizedBox(height: AppSpacing.md),
        _SocialLoginButton(
          label: '네이버로 시작하기',
          backgroundColor: const Color(0xFF03C75A),
          textColor: Colors.white,
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
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), -0.5, -2.2, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 1.7, -1.2, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 2.9, -1.2, true, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), -3.58, -1.2, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.3, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(s * 0.48, s * 0.38, s * 0.52, s * 0.24), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return const Text(
      'N',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
      ),
    );
  }
}

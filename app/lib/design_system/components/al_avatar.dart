import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// 공통 프로필 아바타 컴포넌트
///
/// emerald 그라데이션 원형 배경 위에 텍스트(이름 첫 글자 또는 이모지)를 표시합니다.
/// [imageUrl]이 제공되면 네트워크 이미지를 표시합니다.
/// [AlAvatar.small] (32), [AlAvatar.medium] (44), [AlAvatar.large] (80) 프리셋 제공.
class AlAvatar extends StatelessWidget {
  /// 아바타 안에 표시할 텍스트 (이름 첫 글자 또는 이모지)
  final String text;

  /// 네트워크 이미지 URL (프로필 사진)
  final String? imageUrl;

  /// 아바타 크기 (width = height)
  final double size;

  /// 텍스트 크기 (기본: size * 0.45)
  final double? fontSize;

  /// 그림자 표시 여부 (기본: false)
  final bool showShadow;

  /// 그라데이션 색상 (기본: emerald)
  final List<Color>? gradientColors;

  const AlAvatar({
    super.key,
    required this.text,
    this.imageUrl,
    this.size = 44,
    this.fontSize,
    this.showShadow = false,
    this.gradientColors,
  });

  /// 32dp 작은 아바타
  const AlAvatar.small({
    super.key,
    required this.text,
    this.imageUrl,
    this.gradientColors,
  })  : size = 32,
        fontSize = 14,
        showShadow = false;

  /// 44dp 기본 아바타
  const AlAvatar.medium({
    super.key,
    required this.text,
    this.imageUrl,
    this.gradientColors,
  })  : size = 44,
        fontSize = 20,
        showShadow = false;

  /// 80dp 큰 아바타 (프로필 페이지 등)
  const AlAvatar.large({
    super.key,
    required this.text,
    this.imageUrl,
    this.gradientColors,
  })  : size = 80,
        fontSize = 32,
        showShadow = true;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? size * 0.45;
    final colors = gradientColors ?? [AppColors.emerald400, AppColors.emerald600];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              )
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.emerald600.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              text,
              style: AppTypography.heading3.copyWith(
                color: Colors.white,
                fontSize: effectiveFontSize,
              ),
            )
          : null,
    );
  }
}

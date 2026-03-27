import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';

/// 공통 화면 헤더 컴포넌트
///
/// 흰색 배경 + 하단 구분선 + 제목 + 선택적 뒤로가기/액션/서브타이틀
class AlScreenHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? action;
  final String? subtitle;

  const AlScreenHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.action,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.lg),
                  // 메인 행: 뒤로가기 + 제목 + 액션
                  Row(
                    children: [
                      if (showBack) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: EdgeInsets.only(right: AppSpacing.md),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              size: 24,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(title, style: AppTypography.heading2),
                      ),
                      ?action,
                    ],
                  ),
                  // 서브타이틀
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(subtitle!, style: AppTypography.bodyMedium),
                  ],
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            // 하단 구분선
            Divider(height: 1, thickness: 1, color: AppColors.gray200),
          ],
        ),
      ),
    );
  }
}

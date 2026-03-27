import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_screen_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(title: '더보기'),
          Expanded(
            child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.lg,
            bottom: AppSpacing.bottomNavSafeArea,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 요약 카드
              _buildProfileCard(context),
              SizedBox(height: AppSpacing.sectionGap),

              // 서비스 섹션
              _buildSectionLabel('서비스'),
              SizedBox(height: AppSpacing.sm),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: LucideIcons.users,
                  label: '공유/권한 관리',
                  onTap: () => context.go('/more/access'),
                ),
                _MenuItem(
                  icon: LucideIcons.bell,
                  label: '알림 설정',
                  trailing: _buildComingSoonBadge(),
                ),
              ]),
              SizedBox(height: AppSpacing.lg),

              // 앱 설정 섹션
              _buildSectionLabel('앱 설정'),
              SizedBox(height: AppSpacing.sm),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: LucideIcons.palette,
                  label: '테마 설정',
                  trailing: _buildComingSoonBadge(),
                ),
                _MenuItem(
                  icon: LucideIcons.globe,
                  label: '언어 설정',
                  trailing: Text(
                    '한국어',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ),
                _MenuItem(
                  icon: LucideIcons.download,
                  label: '데이터 내보내기',
                  trailing: _buildComingSoonBadge(),
                ),
              ]),
              SizedBox(height: AppSpacing.lg),

              // 정보 섹션
              _buildSectionLabel('정보'),
              SizedBox(height: AppSpacing.sm),
              _buildMenuGroup(context, [
                _MenuItem(
                  icon: LucideIcons.info,
                  label: '앱 버전',
                  trailing: Text(
                    'v1.0.0',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  showChevron: false,
                ),
                _MenuItem(
                  icon: LucideIcons.fileText,
                  label: '이용약관',
                ),
                _MenuItem(
                  icon: LucideIcons.shield,
                  label: '개인정보처리방침',
                ),
              ]),
              SizedBox(height: AppSpacing.sectionGap),

              // 로그아웃
              AlButton(
                label: '로그아웃',
                variant: AlButtonVariant.danger,
                icon: Icon(LucideIcons.logOut, size: 18, color: AppColors.red600),
                onPressed: () {},
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/more/profile'),
      child: AlCard(
        child: Row(
          children: [
            // 아바타
            const AlAvatar.medium(text: '홍'),
            SizedBox(width: AppSpacing.lg),

            // 이름 + 이메일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('홍길동', style: AppTypography.heading3),
                  SizedBox(height: 2),
                  Text(
                    'hong@assetlog.com',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),

            // 화살표
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: AppColors.gray500),
      ),
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<_MenuItem> items) {
    return AlCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            key: ValueKey(item.label),
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: index == 0 && isLast
                      ? AppRadius.lgAll
                      : index == 0
                          ? BorderRadius.only(
                              topLeft: Radius.circular(AppRadius.lg),
                              topRight: Radius.circular(AppRadius.lg),
                            )
                          : isLast
                              ? BorderRadius.only(
                                  bottomLeft: Radius.circular(AppRadius.lg),
                                  bottomRight: Radius.circular(AppRadius.lg),
                                )
                              : BorderRadius.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPadding,
                      vertical: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20, color: AppColors.gray600),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(item.label, style: AppTypography.bodyLarge),
                        ),
                        if (item.trailing != null) ...[
                          item.trailing!,
                          if (item.showChevron) SizedBox(width: AppSpacing.sm),
                        ],
                        if (item.showChevron)
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.gray400,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: AppColors.gray100,
                  indent: AppSpacing.cardPadding + 32,
                  endIndent: AppSpacing.cardPadding,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        '준비중',
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: AppColors.gray500,
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });
}

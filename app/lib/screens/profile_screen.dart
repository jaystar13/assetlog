import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_screen_header.dart';
import '../utils/user_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _prefs = UserPreferences();

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  void _showSubtitleEditDialog() {
    final controller = TextEditingController(text: _prefs.subtitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('한 줄 소개', style: AppTypography.heading3),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: '나만의 한 줄 소개를 입력하세요',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.gray400),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald600),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.gray600)),
          ),
          TextButton(
            onPressed: () {
              _prefs.setSubtitle(controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text('저장', style: TextStyle(color: AppColors.emerald600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(title: '마이 프로필', showBack: true),
          Expanded(
            child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.xl,
          bottom: AppSpacing.xxl,
        ),
        child: Column(
          children: [
            // 프로필 상단
            _buildProfileHeader(),
            SizedBox(height: AppSpacing.sectionGap),

            // 프로필 정보
            _buildInfoCard(),
            SizedBox(height: AppSpacing.lg),

            // 활동 요약
            _buildActivityCard(),
            SizedBox(height: AppSpacing.sectionGap),

            // 프로필 수정 버튼
            AlButton(
              label: '프로필 수정',
              variant: AlButtonVariant.secondary,
              icon: Icon(LucideIcons.pencil, size: 16, color: AppColors.gray700),
              onPressed: () {
                // TODO: 프로필 수정 기능 구현
              },
            ),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // 큰 아바타
        const AlAvatar.large(text: '홍'),
        SizedBox(height: AppSpacing.lg),

        // 이름
        Text('홍길동', style: AppTypography.heading2),
        SizedBox(height: AppSpacing.xs),

        // 이메일
        Text(
          'hong@assetlog.com',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
        ),
        SizedBox(height: AppSpacing.sm),

        // 한 줄 소개 (탭하여 수정)
        GestureDetector(
          onTap: _showSubtitleEditDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: AppRadius.fullAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _prefs.subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.emerald700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(LucideIcons.pencil, size: 12, color: AppColors.emerald600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기본 정보', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),
          _buildInfoRow(LucideIcons.phone, '연락처', '010-1234-5678'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.calendarPlus, '가입일', '2026-01-15'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.clock, '마지막 로그인', '2026-03-25 09:30'),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('활동 요약', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _buildStatItem('등록 자산', '8', LucideIcons.wallet)),
              Expanded(child: _buildStatItem('이번 달 거래', '5', LucideIcons.arrowLeftRight)),
              Expanded(child: _buildStatItem('공유 멤버', '2', LucideIcons.users)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 18, color: AppColors.gray600),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.gray100);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.emerald600),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: AppTypography.heading3.copyWith(
            color: AppColors.emerald700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

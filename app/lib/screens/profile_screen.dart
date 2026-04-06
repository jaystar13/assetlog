import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/providers.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_screen_header.dart';
import '../utils/user_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

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
            _buildProfileHeader(user),
            SizedBox(height: AppSpacing.sectionGap),
            _buildInfoCard(user),
            SizedBox(height: AppSpacing.lg),
            _buildActivityCard(),
            SizedBox(height: AppSpacing.sectionGap),
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

  Widget _buildProfileHeader(Map<String, dynamic>? user) {
    final name = user?['name'] as String? ?? '사용자';
    final email = user?['email'] as String? ?? '';
    final avatar = user?['avatar'] as String?;
    final initial = name.isNotEmpty ? name.characters.first : '?';

    return Column(
      children: [
        AlAvatar.large(text: initial, imageUrl: avatar),
        SizedBox(height: AppSpacing.lg),
        Text(name, style: AppTypography.heading2),
        SizedBox(height: AppSpacing.xs),
        Text(
          email,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
        ),
        SizedBox(height: AppSpacing.sm),
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

  Widget _buildInfoCard(Map<String, dynamic>? user) {
    final provider = user?['provider'] as String? ?? '-';
    final createdAt = user?['createdAt'] as String? ?? '-';
    final joinDate = createdAt != '-'
        ? createdAt.substring(0, 10)
        : '-';

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기본 정보', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),
          _buildInfoRow(LucideIcons.logIn, '로그인 방식', _providerLabel(provider)),
          _buildDivider(),
          _buildInfoRow(LucideIcons.calendarPlus, '가입일', joinDate),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'kakao':
        return '카카오';
      case 'naver':
        return '네이버';
      default:
        return provider;
    }
  }

  Widget _buildActivityCard() {
    // TODO: 실제 데이터로 교체 (Phase 3 후반)
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('활동 요약', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _buildStatItem('등록 자산', '-', LucideIcons.wallet)),
              Expanded(child: _buildStatItem('이번 달 거래', '-', LucideIcons.arrowLeftRight)),
              Expanded(child: _buildStatItem('공유 멤버', '-', LucideIcons.users)),
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

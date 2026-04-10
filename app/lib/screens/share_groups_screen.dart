import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/enums.dart';
import '../core/providers.dart';
import '../utils/snackbar_helper.dart';

class ShareGroupsScreen extends ConsumerStatefulWidget {
  const ShareGroupsScreen({super.key});

  @override
  ConsumerState<ShareGroupsScreen> createState() => _ShareGroupsScreenState();
}

class _ShareGroupsScreenState extends ConsumerState<ShareGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _receivedInvitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(shareGroupServiceProvider);
      final results = await Future.wait([
        service.getMyGroups(),
        service.getReceivedInvitations(),
      ]);
      if (mounted) {
        setState(() {
          _groups = results[0];
          _receivedInvitations = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateGroupSheet() {
    final nameController = TextEditingController();
    AlBottomSheet.show(
      context: context,
      title: '새 그룹 만들기',
      child: Column(
        children: [
          AlInput(
            label: '그룹 이름',
            placeholder: '예: 우리 가족, 자산 스터디',
            controller: nameController,
          ),
          SizedBox(height: AppSpacing.xl),
          AlButton(
            label: '만들기',
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                showErrorSnackBar(context, '그룹 이름을 입력해 주세요');
                return;
              }
              Navigator.of(context).pop();
              try {
                await ref.read(shareGroupServiceProvider).createGroup(name);
                await _loadData();
                if (mounted) showSuccessSnackBar(context, '그룹이 생성되었습니다');
              } catch (e) {
                if (mounted) showErrorSnackBar(context, '$e');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _receivedInvitations.where((inv) => inv['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(title: '공유 그룹', showBack: true),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.emerald600,
              unselectedLabelColor: AppColors.gray500,
              indicatorColor: AppColors.emerald600,
              indicatorWeight: 2,
              labelStyle: AppTypography.label,
              tabs: [
                Tab(text: '내 그룹'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('받은 초대'),
                      if (pendingCount > 0) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.red600, borderRadius: AppRadius.fullAll),
                          child: Text('$pendingCount', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupsTab(),
                      _buildInvitationsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 내 그룹 탭 ──────────────────────────────

  Widget _buildGroupsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          AlButton(
            label: '새 그룹 만들기',
            icon: Icon(LucideIcons.plus, size: 18, color: Colors.white),
            onPressed: _showCreateGroupSheet,
          ),
          SizedBox(height: AppSpacing.lg),
          if (_groups.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Column(
                children: [
                  Icon(LucideIcons.users, size: 48, color: AppColors.gray300),
                  SizedBox(height: AppSpacing.md),
                  Text('아직 그룹이 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
                  SizedBox(height: AppSpacing.xs),
                  Text('그룹을 만들고 가족이나 친구를 초대해 보세요', style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                ],
              ),
            )
          else
            ..._groups.map(_buildGroupCard),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final members = (group['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final itemCount = group['_count']?['sharedItems'] ?? 0;

    return GestureDetector(
      onTap: () async {
        await context.push('/more/groups/${group['id']}');
        _loadData();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: AlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.users, size: 20, color: AppColors.emerald600),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(group['name'] as String, style: AppTypography.heading3)),
                  Icon(LucideIcons.chevronRight, size: 18, color: AppColors.gray400),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // 멤버 아바타 겹침
                  SizedBox(
                    width: (members.length.clamp(0, 4) * 28).toDouble() + 8,
                    height: 32,
                    child: Stack(
                      children: members.take(4).toList().asMap().entries.map((e) {
                        final user = e.value['user'] as Map<String, dynamic>? ?? {};
                        final name = user['name'] as String? ?? '?';
                        return Positioned(
                          left: e.key * 28.0,
                          child: AlAvatar.small(
                            text: name.isNotEmpty ? name.characters.first : '?',
                            imageUrl: user['avatar'] as String?,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Spacer(),
                  Text('멤버 ${members.length}명', style: AppTypography.caption.copyWith(color: AppColors.gray500)),
                  SizedBox(width: AppSpacing.md),
                  Text('공유 ${itemCount}건', style: AppTypography.caption.copyWith(color: AppColors.gray500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 받은 초대 탭 ────────────────────────────

  Widget _buildInvitationsTab() {
    final pending = _receivedInvitations.where((inv) => inv['status'] == 'pending').toList();
    final others = _receivedInvitations.where((inv) => inv['status'] != 'pending').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          if (pending.isEmpty && others.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Column(
                children: [
                  Icon(LucideIcons.mailOpen, size: 48, color: AppColors.gray300),
                  SizedBox(height: AppSpacing.md),
                  Text('받은 초대가 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
                ],
              ),
            ),
          ...pending.map((inv) => _buildInvitationCard(inv, showActions: true)),
          if (others.isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg),
            ...others.map((inv) => _buildInvitationCard(inv, showActions: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> inv, {required bool showActions}) {
    final group = inv['group'] as Map<String, dynamic>? ?? {};
    final inviter = inv['invitedBy'] as Map<String, dynamic>? ?? {};
    final status = inv['status'] as String? ?? 'pending';
    final role = inv['role'] as String? ?? 'viewer';
    final message = inv['message'] as String?;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: AlCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AlAvatar.medium(
                  text: (inviter['name'] as String? ?? '?').characters.first,
                  imageUrl: inviter['avatar'] as String?,
                  gradientColors: [AppColors.emerald400, AppColors.teal500],
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['name'] as String? ?? '', style: AppTypography.heading3),
                      SizedBox(height: 2),
                      Text('${inviter['name']}님의 초대 · ${GroupRole.fromString(role).label}', style: AppTypography.caption),
                    ],
                  ),
                ),
                if (status != 'pending')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'accepted' ? AppColors.emerald50 : AppColors.gray100,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(
                      status == 'accepted' ? '수락' : status == 'declined' ? '거절' : '만료',
                      style: AppTypography.caption.copyWith(
                        color: status == 'accepted' ? AppColors.emerald700 : AppColors.gray500,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            if (message != null && message.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md),
              Text('"$message"', style: AppTypography.bodySmall.copyWith(color: AppColors.gray600, fontStyle: FontStyle.italic)),
            ],
            if (showActions && status == 'pending') ...[
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AlButton(
                      label: '거절',
                      variant: AlButtonVariant.secondary,
                      onPressed: () async {
                        try {
                          await ref.read(shareGroupServiceProvider).declineInvitation(inv['id'] as String);
                          await _loadData();
                          if (mounted) showInfoSnackBar(context, '초대를 거절했습니다');
                        } catch (e) {
                          if (mounted) showErrorSnackBar(context, '$e');
                        }
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AlButton(
                      label: '수락',
                      onPressed: () async {
                        try {
                          await ref.read(shareGroupServiceProvider).acceptInvitation(inv['id'] as String);
                          await _loadData();
                          if (mounted) showSuccessSnackBar(context, '그룹에 참여했습니다');
                        } catch (e) {
                          if (mounted) showErrorSnackBar(context, '$e');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

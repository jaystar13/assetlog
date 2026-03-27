import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_screen_header.dart';
import '../utils/snackbar_helper.dart';

// ─── Data Models ─────────────────────────────────────────────────────────

class _SharedUser {
  final String id;
  final String name;
  final String email;
  final String avatar;
  String cashflowPermission;
  Map<String, String> assetPermissions;

  _SharedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.cashflowPermission,
    required this.assetPermissions,
  });
}

class _Invitation {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  String status; // 'pending' | 'accepted' | 'declined' | 'expired'
  final String cashflowPermission;
  final Map<String, String> assetPermissions;
  final String? message;
  final String sentDate;
  final String? expiryDate;
  final bool isIncoming;
  final String? inviterName;

  _Invitation({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    required this.status,
    required this.cashflowPermission,
    required this.assetPermissions,
    this.message,
    required this.sentDate,
    this.expiryDate,
    required this.isIncoming,
    this.inviterName,
  });
}

class _AssetSubCategory {
  final String id;
  final String name;
  final IconData icon;
  final String color;

  const _AssetSubCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// ─── Constants ───────────────────────────────────────────────────────────

const List<_AssetSubCategory> _assetSubCategories = [
  _AssetSubCategory(id: 'real-estate', name: '부동산', icon: LucideIcons.home, color: 'blue'),
  _AssetSubCategory(id: 'stocks', name: '주식/투자', icon: LucideIcons.trendingUp, color: 'green'),
  _AssetSubCategory(id: 'cash', name: '현금/예금', icon: LucideIcons.wallet, color: 'purple'),
  _AssetSubCategory(id: 'loans', name: '대출/부채', icon: LucideIcons.creditCard, color: 'red'),
];

// ─── Screen ──────────────────────────────────────────────────────────────

class SharedAccessScreen extends StatefulWidget {
  const SharedAccessScreen({super.key});

  @override
  State<SharedAccessScreen> createState() => _SharedAccessScreenState();
}

class _SharedAccessScreenState extends State<SharedAccessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_SharedUser> _users;
  late List<_Invitation> _sentInvitations;
  late List<_Invitation> _receivedInvitations;
  bool _defaultPublic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _users = [
      _SharedUser(
        id: '1',
        name: '김지은',
        email: 'jieun@example.com',
        avatar: '👩',
        cashflowPermission: 'edit',
        assetPermissions: {
          'real-estate': 'edit',
          'stocks': 'edit',
          'cash': 'edit',
          'loans': 'view',
        },
      ),
      _SharedUser(
        id: '2',
        name: '박민수',
        email: 'minsu@example.com',
        avatar: '👨',
        cashflowPermission: 'view',
        assetPermissions: {
          'real-estate': 'none',
          'stocks': 'view',
          'cash': 'view',
          'loans': 'none',
        },
      ),
    ];

    _sentInvitations = [
      _Invitation(
        id: 'sent-1',
        email: 'sister@example.com',
        name: '홍지수',
        status: 'pending',
        cashflowPermission: 'view',
        assetPermissions: {
          'real-estate': 'view',
          'stocks': 'none',
          'cash': 'view',
          'loans': 'none',
        },
        message: '같이 자산 관리해요!',
        sentDate: '2026-03-24',
        expiryDate: '2026-03-31',
        isIncoming: false,
      ),
      _Invitation(
        id: 'sent-2',
        email: 'friend@example.com',
        status: 'expired',
        cashflowPermission: 'view',
        assetPermissions: {
          'real-estate': 'none',
          'stocks': 'view',
          'cash': 'none',
          'loans': 'none',
        },
        sentDate: '2026-03-10',
        expiryDate: '2026-03-17',
        isIncoming: false,
      ),
    ];

    _receivedInvitations = [
      _Invitation(
        id: 'recv-1',
        email: 'dad@example.com',
        name: '홍아버지',
        avatar: '👨‍🦳',
        status: 'pending',
        cashflowPermission: 'edit',
        assetPermissions: {
          'real-estate': 'edit',
          'stocks': 'edit',
          'cash': 'view',
          'loans': 'none',
        },
        message: '가족 자산을 함께 관리합시다.',
        sentDate: '2026-03-25',
        expiryDate: '2026-04-01',
        isIncoming: true,
        inviterName: '홍아버지',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Permission helpers ────────────────────────────────────────────────

  void _cyclePermission(_SharedUser user, String type, [String? subCategoryId]) {
    setState(() {
      if (type == 'cashflow') {
        user.cashflowPermission = _nextPermission(user.cashflowPermission);
      } else if (type == 'asset' && subCategoryId != null) {
        final current = user.assetPermissions[subCategoryId] ?? 'none';
        user.assetPermissions[subCategoryId] = _nextPermission(current);
      }
    });
  }

  String _nextPermission(String current) {
    switch (current) {
      case 'none':
        return 'view';
      case 'view':
        return 'edit';
      case 'edit':
        return 'none';
      default:
        return 'none';
    }
  }

  void _removeUser(String userId) {
    final name = _users.firstWhere((u) => u.id == userId).name;
    setState(() {
      _users.removeWhere((u) => u.id == userId);
    });
    showSuccessSnackBar(context, "'$name' 사용자가 제거되었습니다");
  }

  // ─── Invitation actions ────────────────────────────────────────────────

  void _cancelInvitation(String id) {
    setState(() {
      _sentInvitations.removeWhere((inv) => inv.id == id);
    });
    showInfoSnackBar(context, '초대가 취소되었습니다');
  }

  void _resendInvitation(_Invitation inv) {
    setState(() {
      inv.status = 'pending';
    });
    showSuccessSnackBar(context, '초대가 재발송되었습니다');
  }

  void _acceptInvitation(_Invitation inv) {
    setState(() {
      inv.status = 'accepted';
      _users.add(_SharedUser(
        id: 'accepted-${inv.id}',
        name: inv.inviterName ?? inv.email.split('@').first,
        email: inv.email,
        avatar: inv.avatar ?? '👤',
        cashflowPermission: inv.cashflowPermission,
        assetPermissions: Map.from(inv.assetPermissions),
      ));
    });
    showSuccessSnackBar(context, '초대를 수락했습니다');
  }

  void _declineInvitation(_Invitation inv) {
    setState(() {
      inv.status = 'declined';
    });
    showInfoSnackBar(context, '초대를 거절했습니다');
  }

  // ─── Invite sheet ──────────────────────────────────────────────────────

  void _showInviteSheet() {
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    String inviteCashflowPerm = 'view';
    Map<String, String> inviteAssetPerms = {
      for (final cat in _assetSubCategories) cat.id: 'none',
    };

    AlBottomSheet.show(
      context: context,
      title: '새 사용자 초대',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlInput(
                label: '이메일 주소',
                placeholder: 'example@email.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSpacing.xl),

              // 수입/지출 권한
              _buildPermissionSection(
                icon: LucideIcons.arrowLeftRight,
                title: '수입/지출',
                permission: inviteCashflowPerm,
                onTap: () {
                  setSheetState(() {
                    inviteCashflowPerm = _nextPermission(inviteCashflowPerm);
                  });
                },
              ),
              SizedBox(height: AppSpacing.lg),

              // 자산 권한
              Text('자산', style: AppTypography.label),
              SizedBox(height: AppSpacing.sm),
              ...(_assetSubCategories.map((cat) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildPermissionSection(
                    icon: cat.icon,
                    title: cat.name,
                    permission: inviteAssetPerms[cat.id] ?? 'none',
                    compact: true,
                    colorKey: cat.color,
                    onTap: () {
                      setSheetState(() {
                        final current = inviteAssetPerms[cat.id] ?? 'none';
                        inviteAssetPerms[cat.id] = _nextPermission(current);
                      });
                    },
                  ),
                );
              })),
              SizedBox(height: AppSpacing.lg),

              // 메시지
              AlInput(
                label: '메시지 (선택사항)',
                placeholder: '초대 메시지를 입력하세요',
                controller: messageController,
                maxLines: 3,
              ),
              SizedBox(height: AppSpacing.xl),

              // 액션 버튼
              Row(
                children: [
                  Expanded(
                    child: AlButton(
                      label: '취소',
                      variant: AlButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AlButton(
                      label: '초대하기',
                      icon: Icon(LucideIcons.send, size: 16, color: Colors.white),
                      onPressed: () {
                        if (emailController.text.trim().isNotEmpty) {
                          final now = DateTime.now();
                          final expiry = now.add(Duration(days: 7));
                          setState(() {
                            _sentInvitations.insert(
                              0,
                              _Invitation(
                                id: now.millisecondsSinceEpoch.toString(),
                                email: emailController.text.trim(),
                                name: null,
                                status: 'pending',
                                cashflowPermission: inviteCashflowPerm,
                                assetPermissions: Map.from(inviteAssetPerms),
                                message: messageController.text.trim().isEmpty
                                    ? null
                                    : messageController.text.trim(),
                                sentDate:
                                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                                expiryDate:
                                    '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
                                isIncoming: false,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                          showSuccessSnackBar(context, '초대가 발송되었습니다');
                          // 보낸 초대 탭으로 이동
                          _tabController.animateTo(1);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }

  // ─── Tab counts ────────────────────────────────────────────────────────

  int get _pendingSentCount =>
      _sentInvitations.where((i) => i.status == 'pending').length;

  int get _pendingReceivedCount =>
      _receivedInvitations.where((i) => i.status == 'pending').length;

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '공유 및 권한 관리',
            showBack: true,
          ),
          Expanded(
            child: Column(
          children: [
            // 헤더 + 보안 안내
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.lg),
                  Text('가족과 함께 자산을 관리하세요', style: AppTypography.bodyMedium),
                  SizedBox(height: AppSpacing.lg),
                  _buildSecurityNotice(),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // 탭 바
            _buildTabBar(),

            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(),
                  _buildSentInvitationsTab(),
                  _buildReceivedInvitationsTab(),
                ],
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.emerald600,
        unselectedLabelColor: AppColors.gray500,
        indicatorColor: AppColors.emerald600,
        indicatorWeight: 2.5,
        labelStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelSmall,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('멤버'),
                SizedBox(width: 4),
                _buildCountBadge(_users.length, AppColors.emerald600),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('보낸 초대'),
                if (_pendingSentCount > 0) ...[
                  SizedBox(width: 4),
                  _buildCountBadge(_pendingSentCount, AppColors.orange500),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('받은 초대'),
                if (_pendingReceivedCount > 0) ...[
                  SizedBox(width: 4),
                  _buildCountBadge(_pendingReceivedCount, AppColors.red600),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── Tab 1: 공유 멤버 ──────────────────────────────────────────────────

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: AppSpacing.bottomNavSafeArea,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 초대 버튼
          AlButton(
            label: '새 사용자 초대',
            icon: Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
            onPressed: _showInviteSheet,
          ),
          SizedBox(height: AppSpacing.sectionGap),

          // 멤버 목록
          Text('공유된 사용자', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),
          if (_users.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.userX,
              message: '공유된 사용자가 없습니다',
            )
          else
            ...List.generate(_users.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _users.length - 1 ? AppSpacing.lg : 0,
                ),
                child: _buildUserCard(_users[index]),
              );
            }),
          SizedBox(height: AppSpacing.sectionGap),
          _buildPrivacySettings(),
        ],
      ),
    );
  }

  // ─── Tab 2: 보낸 초대 ──────────────────────────────────────────────────

  Widget _buildSentInvitationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: AppSpacing.bottomNavSafeArea,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 초대 버튼
          AlButton(
            label: '새 사용자 초대',
            icon: Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
            onPressed: _showInviteSheet,
          ),
          SizedBox(height: AppSpacing.sectionGap),

          if (_sentInvitations.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.send,
              message: '보낸 초대가 없습니다',
            )
          else
            ...List.generate(_sentInvitations.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _sentInvitations.length - 1
                      ? AppSpacing.lg
                      : 0,
                ),
                child: _buildSentInvitationCard(_sentInvitations[index]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSentInvitationCard(_Invitation inv) {
    final statusConfig = _invitationStatusConfig(inv.status);

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이메일/이름 + 상태 배지
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray100,
                ),
                child: Center(
                  child: Icon(LucideIcons.mail, size: 18, color: AppColors.gray500),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name ?? inv.email.split('@').first,
                      style: AppTypography.label,
                    ),
                    SizedBox(height: 2),
                    Text(inv.email, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              _buildStatusBadge(statusConfig),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // 권한 요약
          _buildPermissionSummary(inv),
          SizedBox(height: AppSpacing.md),

          // 날짜 정보
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: AppColors.gray400),
              SizedBox(width: 4),
              Text(
                '발송: ${inv.sentDate}',
                style: AppTypography.caption,
              ),
              if (inv.expiryDate != null) ...[
                SizedBox(width: AppSpacing.md),
                Icon(LucideIcons.clock, size: 12, color: AppColors.gray400),
                SizedBox(width: 4),
                Text(
                  '만료: ${inv.expiryDate}',
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),

          // 액션 버튼
          if (inv.status == 'pending') ...[
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AlButton(
                    label: '초대 취소',
                    variant: AlButtonVariant.danger,
                    onPressed: () => _cancelInvitation(inv.id),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AlButton(
                    label: '재발송',
                    variant: AlButtonVariant.secondary,
                    icon: Icon(LucideIcons.refreshCw, size: 14, color: AppColors.gray700),
                    onPressed: () => _resendInvitation(inv),
                  ),
                ),
              ],
            ),
          ],
          if (inv.status == 'expired' || inv.status == 'declined') ...[
            SizedBox(height: AppSpacing.lg),
            AlButton(
              label: '다시 초대',
              variant: AlButtonVariant.secondary,
              icon: Icon(LucideIcons.send, size: 14, color: AppColors.gray700),
              onPressed: () => _resendInvitation(inv),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Tab 3: 받은 초대 ──────────────────────────────────────────────────

  Widget _buildReceivedInvitationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: AppSpacing.bottomNavSafeArea,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_receivedInvitations.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.mailOpen,
              message: '받은 초대가 없습니다',
            )
          else
            ...List.generate(_receivedInvitations.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _receivedInvitations.length - 1
                      ? AppSpacing.lg
                      : 0,
                ),
                child: _buildReceivedInvitationCard(
                    _receivedInvitations[index]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReceivedInvitationCard(_Invitation inv) {
    final statusConfig = _invitationStatusConfig(inv.status);

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 초대한 사람 정보 + 상태
          Row(
            children: [
              _buildInviterAvatar(inv),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.inviterName ?? inv.email.split('@').first,
                      style: AppTypography.label,
                    ),
                    SizedBox(height: 2),
                    Text(inv.email, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              _buildStatusBadge(statusConfig),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // 초대 메시지
          Text(
            '${inv.inviterName ?? inv.email.split('@').first}님이 자산 공유에 초대했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray700,
            ),
          ),

          // 메시지 인용
          if (inv.message != null && inv.message!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: AppRadius.smAll,
                border: Border(
                  left: BorderSide(color: AppColors.emerald400, width: 3),
                ),
              ),
              child: Text(
                '"${inv.message}"',
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),

          // 부여된 권한 상세
          Text('부여된 권한', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.mdAll,
            ),
            child: Column(
              children: [
                // 수입/지출
                _buildPermissionRow(
                  icon: LucideIcons.arrowLeftRight,
                  title: '수입/지출',
                  permission: inv.cashflowPermission,
                ),
                SizedBox(height: AppSpacing.sm),
                Divider(height: 1, color: AppColors.gray200),
                SizedBox(height: AppSpacing.sm),
                // 자산 카테고리별
                ..._assetSubCategories.map((cat) {
                  final perm = inv.assetPermissions[cat.id] ?? 'none';
                  final isLast = cat.id == _assetSubCategories.last.id;
                  return Column(
                    children: [
                      _buildPermissionRow(
                        icon: cat.icon,
                        title: cat.name,
                        permission: perm,
                        colorKey: cat.color,
                      ),
                      if (!isLast) SizedBox(height: AppSpacing.sm),
                    ],
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // 날짜
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: AppColors.gray400),
              SizedBox(width: 4),
              Text('발송: ${inv.sentDate}', style: AppTypography.caption),
              if (inv.expiryDate != null) ...[
                SizedBox(width: AppSpacing.md),
                Icon(LucideIcons.clock, size: 12, color: AppColors.gray400),
                SizedBox(width: 4),
                Text('만료: ${inv.expiryDate}', style: AppTypography.caption),
              ],
            ],
          ),

          // 액션 버튼 (대기중일 때만)
          if (inv.status == 'pending') ...[
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AlButton(
                    label: '거절',
                    variant: AlButtonVariant.secondary,
                    onPressed: () => _declineInvitation(inv),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AlButton(
                    label: '수락',
                    icon: Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
                    onPressed: () => _acceptInvitation(inv),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviterAvatar(_Invitation inv) {
    return AlAvatar.medium(
      text: inv.avatar ?? '👤',
      gradientColors: [AppColors.emerald400, AppColors.teal500],
    );
  }

  // ─── Permission summary (한 줄 요약) ───────────────────────────────────

  Widget _buildPermissionSummary(_Invitation inv) {
    final parts = <String>[];
    if (inv.cashflowPermission != 'none') {
      parts.add('수입/지출: ${_permLabel(inv.cashflowPermission)}');
    }
    final assetPerms = inv.assetPermissions.entries
        .where((e) => e.value != 'none')
        .map((e) {
      final cat = _assetSubCategories.firstWhere((c) => c.id == e.key);
      return '${cat.name}(${_permLabel(e.value)})';
    });
    if (assetPerms.isNotEmpty) {
      parts.add('자산: ${assetPerms.join(', ')}');
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        parts.isEmpty ? '권한 없음' : parts.join(' / '),
        style: AppTypography.caption.copyWith(color: AppColors.gray600),
      ),
    );
  }

  String _permLabel(String perm) {
    switch (perm) {
      case 'edit':
        return '편집';
      case 'view':
        return '보기';
      default:
        return '없음';
    }
  }

  // ─── Permission row (읽기 전용, 받은 초대용) ───────────────────────────

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String permission,
    String? colorKey,
  }) {
    return Row(
      children: [
        if (colorKey != null)
          _buildColoredIcon(icon, colorKey, compact: true)
        else
          Icon(icon, size: 14, color: AppColors.gray600),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(color: AppColors.gray700),
          ),
        ),
        _buildPermissionBadge(permission),
      ],
    );
  }

  // ─── Status badge ──────────────────────────────────────────────────────

  Widget _buildStatusBadge(_InvitationStatusConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.textColor),
          SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _InvitationStatusConfig _invitationStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return _InvitationStatusConfig(
          label: '대기중',
          icon: LucideIcons.clock,
          bgColor: AppColors.orange50,
          borderColor: AppColors.orange200,
          textColor: AppColors.orange600,
        );
      case 'accepted':
        return _InvitationStatusConfig(
          label: '수락됨',
          icon: LucideIcons.checkCircle,
          bgColor: AppColors.emerald50,
          borderColor: AppColors.emerald200,
          textColor: AppColors.emerald700,
        );
      case 'declined':
        return _InvitationStatusConfig(
          label: '거절됨',
          icon: LucideIcons.xCircle,
          bgColor: AppColors.red50,
          borderColor: AppColors.red100,
          textColor: AppColors.red600,
        );
      case 'expired':
        return _InvitationStatusConfig(
          label: '만료됨',
          icon: LucideIcons.alertCircle,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          textColor: AppColors.gray500,
        );
      default:
        return _InvitationStatusConfig(
          label: '알 수 없음',
          icon: LucideIcons.helpCircle,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          textColor: AppColors.gray500,
        );
    }
  }

  // ─── Empty state ───────────────────────────────────────────────────────

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return AlCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              Icon(icon, size: 40, color: AppColors.gray300),
              SizedBox(height: AppSpacing.md),
              Text(message, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shared components (기존 유지) ─────────────────────────────────────

  Widget _buildSecurityNotice() {
    return AlCard(
      gradient: LinearGradient(
        colors: [AppColors.blue600, AppColors.blue900],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, size: 24, color: Colors.white),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보안 안내',
                  style: AppTypography.label.copyWith(color: Colors.white),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '공유된 사용자는 허용된 카테고리의 자산 정보만 볼 수 있습니다. 민감한 정보는 신중하게 공유해 주세요.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(_SharedUser user) {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(user),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTypography.label),
                    SizedBox(height: 2),
                    Text(user.email, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),

          _buildPermissionSection(
            icon: LucideIcons.arrowLeftRight,
            title: '수입/지출',
            permission: user.cashflowPermission,
            onTap: () => _cyclePermission(user, 'cashflow'),
          ),
          SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Icon(LucideIcons.pieChart, size: 16, color: AppColors.gray600),
              SizedBox(width: AppSpacing.sm),
              Text('자산', style: AppTypography.label),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.mdAll,
            ),
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: _assetSubCategories.map((cat) {
                final perm = user.assetPermissions[cat.id] ?? 'none';
                final isLast = cat.id == _assetSubCategories.last.id;
                return Column(
                  children: [
                    _buildPermissionSection(
                      icon: cat.icon,
                      title: cat.name,
                      permission: perm,
                      compact: true,
                      colorKey: cat.color,
                      onTap: () => _cyclePermission(user, 'asset', cat.id),
                    ),
                    if (!isLast) SizedBox(height: AppSpacing.sm),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          Align(
            alignment: Alignment.centerRight,
            child: AlButton(
              label: '사용자 제거',
              variant: AlButtonVariant.danger,
              icon: Icon(LucideIcons.trash2, size: 14, color: AppColors.red600),
              fullWidth: false,
              onPressed: () => _removeUser(user.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(_SharedUser user) {
    return AlAvatar.medium(
      text: user.avatar,
      gradientColors: [AppColors.emerald400, AppColors.teal500],
    );
  }

  Widget _buildPermissionSection({
    required IconData icon,
    required String title,
    required String permission,
    required VoidCallback onTap,
    bool compact = false,
    String? colorKey,
  }) {
    return Row(
      children: [
        if (colorKey != null) ...[
          _buildColoredIcon(icon, colorKey, compact: compact),
        ] else ...[
          Icon(icon, size: compact ? 14 : 16, color: AppColors.gray600),
        ],
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: compact
                ? AppTypography.bodySmall.copyWith(color: AppColors.gray700)
                : AppTypography.label,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: _buildPermissionBadge(permission),
        ),
      ],
    );
  }

  Widget _buildColoredIcon(IconData icon, String colorKey, {bool compact = false}) {
    final categoryColors = AppColors.category[colorKey];
    final bgColor = categoryColors?.light ?? AppColors.gray100;
    final iconColor = categoryColors?.bg ?? AppColors.gray500;
    final size = compact ? 28.0 : 32.0;
    final iconSize = compact ? 14.0 : 16.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }

  Widget _buildPermissionBadge(String permission) {
    final config = _permissionConfig(permission);
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.textColor),
          SizedBox(width: 4),
          Text(
            config.label,
            style: AppTypography.labelSmall.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  _PermissionBadgeConfig _permissionConfig(String permission) {
    switch (permission) {
      case 'edit':
        return _PermissionBadgeConfig(
          label: '편집',
          icon: LucideIcons.edit3,
          bgColor: AppColors.emerald50,
          borderColor: AppColors.emerald200,
          textColor: AppColors.emerald700,
        );
      case 'view':
        return _PermissionBadgeConfig(
          label: '보기',
          icon: LucideIcons.eye,
          bgColor: AppColors.blue50,
          borderColor: AppColors.blue200,
          textColor: AppColors.blue700,
        );
      default:
        return _PermissionBadgeConfig(
          label: '없음',
          icon: LucideIcons.eyeOff,
          bgColor: AppColors.gray50,
          borderColor: AppColors.gray200,
          textColor: AppColors.gray400,
        );
    }
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('개인정보 설정', style: AppTypography.heading3),
        SizedBox(height: AppSpacing.lg),
        AlCard(
          child: Row(
            children: [
              Icon(LucideIcons.globe, size: 20, color: AppColors.gray600),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('기본 공개 설정', style: AppTypography.label),
                    SizedBox(height: 2),
                    Text(
                      '새로 추가하는 자산을 공유 사용자에게 자동으로 공개합니다',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Switch(
                value: _defaultPublic,
                onChanged: (v) => setState(() => _defaultPublic = v),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.emerald600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────────────────

class _PermissionBadgeConfig {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  _PermissionBadgeConfig({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}

class _InvitationStatusConfig {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  _InvitationStatusConfig({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}

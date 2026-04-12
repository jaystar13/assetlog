import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_confirm_dialog.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';
import '../utils/date_format.dart';
import '../utils/snackbar_helper.dart';

class ShareGroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const ShareGroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<ShareGroupDetailScreen> createState() => _ShareGroupDetailScreenState();
}

class _ShareGroupDetailScreenState extends ConsumerState<ShareGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  bool _showAssets = false; // 공유 데이터 탭: false=거래, true=자산

  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoading = true;

  String get _monthKey => toMonthKey(_selectedMonth);

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
        service.getGroup(widget.groupId),
        service.getGroupTransactions(widget.groupId, month: _monthKey),
        service.getGroupAssets(widget.groupId, month: _monthKey),
        service.getActivityLogs(widget.groupId),
      ]);
      if (mounted) {
        setState(() {
          _group = results[0] as Map<String, dynamic>;
          _transactions = (results[1] as List).cast<Map<String, dynamic>>();
          _assets = (results[2] as List).cast<Map<String, dynamic>>();
          _activityLogs = (results[3] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPreviousMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _loadData();
  }

  void _goToNextMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    _loadData();
  }

  static const _memberColors = [
    '#14B8A6', // teal
    '#9333EA', // purple
    '#2563EB', // blue
    '#F59E0B', // amber
    '#DC2626', // red
    '#059669', // emerald
    '#DB2777', // pink
    '#EA580C', // orange
  ];

  void _showInviteSheet() {
    final emailController = TextEditingController();
    final nicknameController = TextEditingController();
    String selectedColor = _memberColors[0];

    AlBottomSheet.show(
      context: context,
      title: '멤버 초대',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlInput(label: '이메일', placeholder: 'example@email.com', controller: emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.lg),
            AlInput(label: '별명', placeholder: '예: 아내, 아들, 친구A', controller: nicknameController),
            const SizedBox(height: AppSpacing.lg),
            Text('표시 색상', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _memberColors.map((hex) {
                final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
                final isSelected = selectedColor == hex;
                return GestureDetector(
                  onTap: () => setSheetState(() => selectedColor = hex),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.gray900, width: 3) : null,
                    ),
                    child: isSelected ? Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AlButton(
              label: '초대하기',
              icon: Icon(LucideIcons.send, size: 16, color: Colors.white),
              onPressed: () async {
                final email = emailController.text.trim();
                final nickname = nicknameController.text.trim();
                if (email.isEmpty) { showErrorSnackBar(context, '이메일을 입력해 주세요'); return; }
                Navigator.of(context).pop();
                try {
                  await ref.read(shareGroupServiceProvider).inviteToGroup(
                    widget.groupId,
                    toEmail: email,
                    nickname: nickname.isNotEmpty ? nickname : null,
                    color: selectedColor,
                  );
                  await _loadData();
                  if (mounted) showSuccessSnackBar(context, '초대를 보냈습니다');
                } catch (e) {
                  if (mounted) showErrorSnackBar(context, '$e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupName = _group?['name'] as String? ?? '그룹';
    final members = (_group?['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(title: groupName, showBack: true),
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
                Tab(text: '멤버 관리'),
                Tab(text: '공유 데이터'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMemberManagementTab(members),
                      _buildSharedDataTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── 멤버 관리 탭 (멤버 + 초대 + 이력 통합) ──────────

  Widget _buildMemberManagementTab(List<Map<String, dynamic>> members) {
    final authUser = ref.watch(authNotifierProvider).user;
    final myUserId = authUser?['id'] as String? ?? '';
    final myMember = members.where((m) => (m['user'] as Map?)?['id'] == myUserId).firstOrNull;
    final isAdmin = myMember?['role'] == 'admin';

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 초대 버튼
          if (isAdmin)
            AlButton(
              label: '멤버 초대',
              icon: Icon(LucideIcons.userPlus, size: 18, color: Colors.white),
              onPressed: _showInviteSheet,
            ),
          if (isAdmin) const SizedBox(height: AppSpacing.lg),

          // 멤버 목록
          Text('멤버', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.md),
          ..._buildMemberList(members, myUserId, isAdmin),

          // 그룹 나가기/삭제
          const SizedBox(height: AppSpacing.sectionGap),
          if (isAdmin)
            AlButton(
              label: '그룹 삭제',
              variant: AlButtonVariant.danger,
              icon: Icon(LucideIcons.trash2, size: 18, color: Colors.white),
              onPressed: () => _confirmGroupDelete(),
            )
          else
            AlButton(
              label: '그룹 나가기',
              variant: AlButtonVariant.danger,
              icon: Icon(LucideIcons.logOut, size: 18, color: Colors.white),
              onPressed: () => _confirmGroupLeave(),
            ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('멤버를 길게 눌러 제거할 수 있습니다', style: AppTypography.caption.copyWith(color: AppColors.gray400)),
          ],

          // 활동 이력
          const SizedBox(height: AppSpacing.sectionGap),
          Text('활동 이력', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.md),
          if (_activityLogs.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: Text('활동 이력이 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500))),
            )
          else
            ..._activityLogs.map(_buildActivityItem),
        ],
      ),
    );
  }

  void _confirmGroupDelete() {
    AlConfirmDialog.show(
      context: context,
      title: '그룹 삭제',
      message: '이 그룹을 삭제하시겠습니까?\n모든 멤버와 공유 데이터가 삭제됩니다.',
      onConfirm: () async {
        try {
          await ref.read(shareGroupServiceProvider).deleteGroup(widget.groupId);
          if (mounted) { showSuccessSnackBar(context, '그룹이 삭제되었습니다'); Navigator.of(context).pop(); }
        } catch (e) { if (mounted) showErrorSnackBar(context, '$e'); }
      },
    );
  }

  void _confirmGroupLeave() {
    AlConfirmDialog.show(
      context: context,
      title: '그룹 나가기',
      message: '이 그룹을 나가시겠습니까?\n공유된 데이터는 더 이상 볼 수 없습니다.',
      confirmLabel: '나가기',
      onConfirm: () async {
        try {
          await ref.read(shareGroupServiceProvider).leaveGroup(widget.groupId);
          if (mounted) { showSuccessSnackBar(context, '그룹을 나갔습니다'); Navigator.of(context).pop(); }
        } catch (e) { if (mounted) showErrorSnackBar(context, '$e'); }
      },
    );
  }

  // ─── 공유 데이터 탭 (월 선택기 + 거래/자산 전환) ──────

  Widget _buildSharedDataTab() {
    return Column(
      children: [
        AlMonthSelector(selectedMonth: _selectedMonth, onPrevious: _goToPreviousMonth, onNext: _goToNextMonth),
        // 거래/자산 세그먼트
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: _buildSegmentButton('거래', !_showAssets, () => setState(() => _showAssets = false))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildSegmentButton('자산', _showAssets, () => setState(() => _showAssets = true))),
            ],
          ),
        ),
        Expanded(child: _showAssets ? _buildAssetsTab() : _buildTransactionsTab()),
      ],
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald600 : Colors.transparent,
          borderRadius: AppRadius.fullAll,
          border: Border.all(color: isSelected ? AppColors.emerald600 : AppColors.gray300),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTypography.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.gray600,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }

  // ─── 멤버 탭 ──────────────────────────────────

  List<Widget> _buildMemberList(List<Map<String, dynamic>> members, String myUserId, bool isAdmin) {
    return [
          ...members.map((member) {
          final user = member['user'] as Map<String, dynamic>? ?? {};
          final memberId = member['id'] as String;
          final userId = user['id'] as String? ?? '';
          final name = member['nickname'] as String? ?? user['name'] as String? ?? '';
          final email = user['email'] as String? ?? '';
          final role = member['role'] as String? ?? 'viewer';
          final roleLabel = GroupRole.fromString(role).label;
          final isMe = userId == myUserId;
          final color = member['color'] as String?;

          return GestureDetector(
            onLongPress: (isAdmin && !isMe) ? () {
              AlConfirmDialog.show(
                context: context,
                title: '멤버 제거',
                message: "'$name'님을 그룹에서 제거하시겠습니까?\n공유된 데이터는 더 이상 볼 수 없습니다.",
                confirmLabel: '제거',
                onConfirm: () async {
                  try {
                    await ref.read(shareGroupServiceProvider).removeMember(widget.groupId, memberId);
                    await _loadData();
                    if (mounted) showSuccessSnackBar(context, "'$name'님이 제거되었습니다");
                  } catch (e) {
                    if (mounted) showErrorSnackBar(context, '$e');
                  }
                },
              );
            } : null,
            child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  AlAvatar.medium(
                    text: name.isNotEmpty ? name.characters.first : '?',
                    imageUrl: user['avatar'] as String?,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(name, style: AppTypography.label),
                          if (isMe) Text(' (나)', style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                        ]),
                        SizedBox(height: 2),
                        Text(email, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  if (color != null)
                    Container(
                      width: 12, height: 12, margin: EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${color.substring(1)}', radix: 16)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: role == 'admin' ? AppColors.emerald50 : AppColors.gray100,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(roleLabel, style: AppTypography.caption.copyWith(
                      color: role == 'admin' ? AppColors.emerald700 : AppColors.gray600,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    )),
                  ),
                ],
              ),
            ),
            ),
          );
        }),
    ];
  }

  // ─── 거래 탭 ──────────────────────────────────

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: AppColors.gray300),
          const SizedBox(height: AppSpacing.md),
          Text('공유된 거래가 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
        ],
      ));
    }

    // 소유자별 색상
    final members = (_group?['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final memberColorMap = <String, Color>{};
    for (final m in members) {
      final userId = (m['user'] as Map?)?['id'] as String? ?? '';
      final hex = m['color'] as String?;
      if (hex != null && userId.isNotEmpty) {
        memberColorMap[userId] = Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
    }
    final memberNicknameMap = <String, String>{};
    for (final m in members) {
      final userId = (m['user'] as Map?)?['id'] as String? ?? '';
      final nickname = m['nickname'] as String?;
      final userName = (m['user'] as Map?)?['name'] as String? ?? '';
      memberNicknameMap[userId] = nickname ?? userName;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: _transactions.map((raw) {
          final type = raw['type'] as String? ?? 'expense';
          final isIncome = type == 'income';
          final name = raw['name'] as String? ?? '';
          final amount = (raw['amount'] as num?)?.toInt() ?? 0;
          final date = raw['date'] as String? ?? '';
          final category = raw['category'] as String? ?? '';
          final subCategory = raw['subCategory'] as String? ?? raw['sub_category'] as String? ?? '';
          final ownerId = raw['userId'] as String? ?? raw['user_id'] as String? ?? '';
          final ownerName = memberNicknameMap[ownerId] ?? (raw['user'] as Map?)?['name'] as String? ?? '';
          final ownerColor = memberColorMap[ownerId] ?? AppColors.teal500;

          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: ownerColor.withValues(alpha: 0.04),
              borderRadius: AppRadius.lgAll,
            ),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
                      const SizedBox(height: AppSpacing.xs),
                      Row(children: [
                        Text(category, style: AppTypography.caption),
                        if (subCategory.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(subCategory, style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                        ],
                        const SizedBox(width: AppSpacing.sm),
                        Text(date.length >= 10 ? date.substring(0, 10) : date, style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: ownerColor.withValues(alpha: 0.1), borderRadius: AppRadius.fullAll),
                          child: Text(ownerName, style: AppTypography.caption.copyWith(color: ownerColor, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                        )),
                      ]),
                    ],
                  )),
                  Text(
                    '${isIncome ? '+' : '-'}${formatKoreanWon(amount)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isIncome ? AppColors.green600 : AppColors.red600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 자산 탭 ──────────────────────────────────

  Widget _buildAssetsTab() {
    if (_assets.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet, size: 48, color: AppColors.gray300),
          const SizedBox(height: AppSpacing.md),
          Text('공유된 자산이 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: _assets.map((raw) {
          final name = raw['name'] as String? ?? '';
          final catId = raw['categoryId'] as String? ?? '';
          final history = raw['valueHistory'] as List<dynamic>? ?? [];
          final value = history.isNotEmpty ? (history.first['value'] as num).toInt() : 0;
          final owner = raw['user'] as Map<String, dynamic>? ?? {};
          final ownerName = owner['name'] as String? ?? '';

          final catConfig = {
            'real-estate': (label: '부동산', icon: LucideIcons.home, color: AppColors.blue600),
            'stocks': (label: '주식', icon: LucideIcons.trendingUp, color: AppColors.green600),
            'cash': (label: '현금', icon: LucideIcons.banknote, color: AppColors.purple600),
            'loans': (label: '부채', icon: LucideIcons.creditCard, color: AppColors.red600),
          };
          final config = catConfig[catId];

          return Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AlCard(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(config?.icon ?? LucideIcons.folder, size: 20, color: config?.color ?? AppColors.gray500),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.bodyMedium),
                      SizedBox(height: 2),
                      Text('${config?.label ?? catId} · $ownerName', style: AppTypography.caption),
                    ],
                  )),
                  Text(formatKoreanWon(value), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 활동 이력 탭 ─────────────────────────────

  static const _actionLabels = {
    'invited': '초대함',
    'accepted': '수락함',
    'declined': '거절함',
    'member_removed': '멤버 제거',
    'member_left': '그룹 탈퇴',
    'group_deleted': '그룹 삭제',
  };

  static const _actionIcons = {
    'invited': LucideIcons.send,
    'accepted': LucideIcons.userCheck,
    'declined': LucideIcons.userX,
    'member_removed': LucideIcons.userMinus,
    'member_left': LucideIcons.logOut,
    'group_deleted': LucideIcons.trash2,
  };

  static const _actionColors = {
    'invited': AppColors.blue600,
    'accepted': AppColors.emerald500,
    'declined': AppColors.red600,
    'member_removed': AppColors.red600,
    'member_left': AppColors.gray500,
    'group_deleted': AppColors.red600,
  };

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final actor = log['actor'] as Map<String, dynamic>? ?? {};
    final actorName = actor['name'] as String? ?? '';
    final targetNickname = log['targetNickname'] as String?;
    final targetEmail = log['targetEmail'] as String?;
    final createdAt = log['createdAt'] as String? ?? '';
    final date = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
    final time = createdAt.length >= 16 ? createdAt.substring(11, 16) : '';

    final icon = _actionIcons[action] ?? LucideIcons.activity;
    final color = _actionColors[action] ?? AppColors.gray500;
    final label = _actionLabels[action] ?? action;

    final target = targetNickname ?? targetEmail ?? '';
    String description;
    switch (action) {
      case 'invited':
        description = '$actorName님이 $target님을 초대했습니다';
      case 'accepted':
        description = '${targetNickname ?? actorName}님이 초대를 수락했습니다';
      case 'declined':
        description = '${targetNickname ?? actorName}님이 초대를 거절했습니다';
      case 'member_removed':
        description = '$actorName님이 $target님을 제거했습니다';
      case 'member_left':
        description = '${targetNickname ?? actorName}님이 그룹을 나갔습니다';
      case 'group_deleted':
        description = '$actorName님이 그룹을 삭제했습니다';
      default:
        description = '$actorName님이 $label';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: AppTypography.bodySmall),
              if (targetEmail != null && targetEmail.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(targetEmail, style: AppTypography.caption.copyWith(color: AppColors.gray500)),
              ],
              SizedBox(height: 2),
              Text('$date $time', style: AppTypography.caption.copyWith(color: AppColors.gray400)),
            ],
          )),
        ],
      ),
    );
  }
}

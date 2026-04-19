import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_confirm_dialog.dart';
import '../design_system/components/al_change_indicator.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/notifiers/asset_notifier.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';
import '../utils/date_format.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/asset_tracker/asset_form_sheets.dart';
import '../widgets/asset_tracker/asset_pie_chart_card.dart';

class AssetTrackerScreen extends ConsumerStatefulWidget {
  const AssetTrackerScreen({super.key});

  @override
  ConsumerState<AssetTrackerScreen> createState() => _AssetTrackerScreenState();
}

class _AssetTrackerScreenState extends ConsumerState<AssetTrackerScreen> {
  DateTime _selectedMonth = DateTime.now();
  final Set<String> _expandedGroups = {};

  // 그룹 전환
  String? _selectedGroupId;
  String _selectedGroupName = '나';
  List<Map<String, dynamic>> _myGroups = [];
  bool _groupsLoaded = false;

  // 시트 재진입 방지
  bool _isAddAssetSheetOpen = false;
  bool _isEditAssetSheetOpen = false;

  String get _monthKey => toMonthKey(_selectedMonth);

  void _toggleGroup(String id) {
    setState(() {
      if (_expandedGroups.contains(id)) {
        _expandedGroups.remove(id);
      } else {
        _expandedGroups.add(id);
      }
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  // ─── 새 자산 추가 Bottom Sheet ──────────────────────────────────────
  void _showAddAssetSheet() async {
    if (_isAddAssetSheetOpen) return;
    _isAddAssetSheetOpen = true;
    try {
      final groups =
          ref.read(assetNotifierProvider(_monthKey)).valueOrNull ?? [];
      List<Map<String, dynamic>> shareGroups = [];
      try {
        shareGroups = await ref.read(shareGroupServiceProvider).getMyGroups();
      } catch (_) { /* 공유 그룹 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
      if (!mounted) return;

      await AlBottomSheet.show(
        context: context,
        title: '새 자산 추가',
        child: AddAssetForm(
          assetGroups: groups,
          shareGroups: shareGroups,
          onSubmit: ({
            required String categoryId,
            required String name,
            required int value,
            List<String>? shareGroupIds,
          }) async {
            await ref.read(assetNotifierProvider(_monthKey).notifier).addAsset(
                  categoryId: categoryId,
                  name: name,
                  initialValue: value,
                  shareGroupIds: shareGroupIds,
                );
            _expandedGroups.add(categoryId);
            if (mounted) showSuccessSnackBar(context, '자산이 추가되었습니다');
          },
        ),
      );
    } finally {
      _isAddAssetSheetOpen = false;
    }
  }

  // ─── 개별 자산 수정 Bottom Sheet ─────────────────────────────────────
  void _showEditAssetSheet(AssetItem item, AssetGroup group) async {
    if (_isEditAssetSheetOpen) return;
    _isEditAssetSheetOpen = true;
    try {
      await AlBottomSheet.show(
        context: context,
        title: '자산 수정',
        child: EditAssetForm(
          item: item,
          group: group,
          onSubmit: ({
            required String assetId,
            required String name,
            required int value,
          }) async {
            await ref
                .read(assetNotifierProvider(_monthKey).notifier)
                .updateAssetValue(
                    assetId: assetId, month: _monthKey, value: value);
            if (mounted) showSuccessSnackBar(context, '자산이 수정되었습니다');
          },
        ),
      );
    } finally {
      _isEditAssetSheetOpen = false;
    }
  }

  // ─── 개별 자산 액션 시트 (종료/삭제) ─────────────────────────────────
  void _showAssetActionSheet(AssetItem item, AssetGroup group) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.md,
                ),
                child: Text(item.name, style: AppTypography.heading3),
              ),
              ListTile(
                leading: Icon(LucideIcons.archive, color: AppColors.gray600),
                title: Text('자산 종료', style: AppTypography.bodyLarge),
                subtitle: Text(
                  '목록에서 숨기고 히스토리는 보존합니다',
                  style: AppTypography.caption,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AlConfirmDialog.show(
                    context: context,
                    title: '자산 종료',
                    message:
                        "'${item.name}'을(를) 종료하시겠습니까?\n히스토리는 보존되며, 목록에서 숨겨집니다.",
                    confirmLabel: '종료',
                    isDestructive: false,
                    onConfirm: () async {
                      await ref
                          .read(assetNotifierProvider(_monthKey).notifier)
                          .closeAsset(item.id);
                      if (mounted) {
                        showSuccessSnackBar(
                          context,
                          "'${item.name}'이(가) 종료되었습니다",
                        );
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: AppColors.red600),
                title: Text(
                  '자산 삭제',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.red600,
                  ),
                ),
                subtitle: Text(
                  '자산과 모든 히스토리를 완전히 삭제합니다',
                  style: AppTypography.caption,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AlConfirmDialog.show(
                    context: context,
                    title: '자산 삭제',
                    message:
                        "'${item.name}'과(와) 모든 히스토리를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
                    onConfirm: () async {
                      await ref
                          .read(assetNotifierProvider(_monthKey).notifier)
                          .deleteAsset(item.id);
                      if (mounted) {
                        showSuccessSnackBar(
                          context,
                          "'${item.name}'이(가) 삭제되었습니다",
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateSheet(AssetGroup group) {
    AlBottomSheet.show(
      context: context,
      title: '${group.name} 업데이트',
      child: UpdateAssetsForm(
        group: group,
        onSubmit: (updates) async {
          final notifier = ref.read(assetNotifierProvider(_monthKey).notifier);
          for (final entry in updates.entries) {
            await notifier.updateAssetValue(
              assetId: entry.key,
              month: _monthKey,
              value: entry.value,
            );
          }
          if (mounted) showSuccessSnackBar(context, '자산이 업데이트되었습니다');
        },
      ),
    );
  }

  bool get _isGroupMode => _selectedGroupId != null;

  Future<void> _loadGroups() async {
    if (_groupsLoaded) return;
    _groupsLoaded = true;
    try {
      final groups = await ref.read(shareGroupServiceProvider).getMyGroups();
      if (mounted) setState(() => _myGroups = groups);
    } catch (_) { /* 공유 그룹 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
  }

  void _showGroupSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                LucideIcons.user,
                color: _selectedGroupId == null
                    ? AppColors.emerald600
                    : AppColors.gray500,
              ),
              title: Text('나', style: AppTypography.bodyLarge),
              trailing: _selectedGroupId == null
                  ? Icon(
                      LucideIcons.check,
                      size: 18,
                      color: AppColors.emerald600,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedGroupId = null;
                  _selectedGroupName = '나';
                });
                Navigator.pop(ctx);
              },
            ),
            ..._myGroups.map((g) {
              final gId = g['id'] as String;
              final gName = g['name'] as String;
              final memberCount = (g['members'] as List?)?.length ?? 0;
              final displayName = '$gName($memberCount명)';
              final sel = _selectedGroupId == gId;
              return ListTile(
                leading: Icon(
                  LucideIcons.users,
                  color: sel ? AppColors.emerald600 : AppColors.gray500,
                ),
                title: Text(displayName, style: AppTypography.bodyLarge),
                trailing: sel
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: AppColors.emerald600,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedGroupId = gId;
                    _selectedGroupName = displayName;
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadGroups();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '자산 현황',
            subtitle: '나의 자산을 카테고리별로 관리하세요',
            action: _myGroups.isNotEmpty
                ? GestureDetector(
                    onTap: _showGroupSelector,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isGroupMode
                            ? AppColors.emerald50
                            : AppColors.gray50,
                        borderRadius: AppRadius.fullAll,
                        border: Border.all(
                          color: _isGroupMode
                              ? AppColors.emerald500
                              : AppColors.gray200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isGroupMode ? LucideIcons.users : LucideIcons.user,
                            size: 14,
                            color: _isGroupMode
                                ? AppColors.emerald600
                                : AppColors.gray600,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _selectedGroupName,
                            style: AppTypography.bodySmall.copyWith(
                              color: _isGroupMode
                                  ? AppColors.emerald700
                                  : AppColors.gray600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 12,
                            color: AppColors.gray400,
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),

          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          Expanded(child: _buildAssetContent()),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _sharedAssets = [];
  String? _lastAssetGroupKey;

  Future<void> _loadSharedAssets() async {
    final key = '${_selectedGroupId}_$_monthKey';
    if (_lastAssetGroupKey == key) return;
    if (_selectedGroupId == null) {
      _sharedAssets = [];
      _lastAssetGroupKey = key;
      return;
    }
    try {
      final assets = await ref
          .read(shareGroupServiceProvider)
          .getGroupAssets(_selectedGroupId!, month: _monthKey);
      if (mounted) {
        setState(() {
          _sharedAssets = assets;
          _lastAssetGroupKey = key;
        });
      }
    } catch (_) { /* 공유 그룹 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
  }

  Widget _buildAssetContent() {
    if (_isGroupMode) _loadSharedAssets();
    // 그룹 모드 해제 시 공유 데이터 클리어
    if (!_isGroupMode && _sharedAssets.isNotEmpty) {
      _sharedAssets = [];
      _lastAssetGroupKey = null;
    }
    return ref
        .watch(assetNotifierProvider(_monthKey))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '데이터를 불러올 수 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(assetNotifierProvider(_monthKey)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (groups) => SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.bottomNavSafeArea,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                AssetPieChartCard(groups: groups),
                const SizedBox(height: AppSpacing.sectionGap),
                ...groups.map((group) {
                  // 그룹 모드일 때 해당 카테고리의 공유 자산을 합침
                  final sharedInCategory = _isGroupMode
                      ? _sharedAssets
                            .where((a) => a['categoryId'] == group.id)
                            .toList()
                      : <Map<String, dynamic>>[];
                  return Padding(
                    key: ValueKey(group.id),
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _buildAssetGroupCard(
                      group,
                      sharedAssets: sharedInCategory,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),
                _buildAddAssetButton(),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        );
  }

  // ─── Asset Group Card ────────────────────────────────────────────────

  Widget _buildAssetGroupCard(
    AssetGroup group, {
    List<Map<String, dynamic>> sharedAssets = const [],
  }) {
    final isExpanded = _expandedGroups.contains(group.id);
    final categoryColors = group.colors;

    return AlCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header (tap to expand/collapse)
          InkWell(
            onTap: () => _toggleGroup(group.id),
            borderRadius: isExpanded
                ? BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  )
                : AppRadius.lgAll,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColors.light,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      group.icon,
                      size: 22,
                      color: categoryColors.text,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Name and item count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: AppTypography.label),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${group.items.length}개',
                              style: AppTypography.bodySmall,
                            ),
                            if (sharedAssets.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '· 공유 ${sharedAssets.length}개',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.teal500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Total value and change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKoreanWon(group.totalValue),
                        style: AppTypography.amountSmall,
                      ),
                      SizedBox(height: 2),
                      if (group.changePercent != 0)
                        AlChangeIndicator.percent(
                          percent: group.changePercent,
                          iconSize: 14,
                          fontSize: 12,
                        )
                      else
                        Text('전월 동일', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Expand/collapse chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: _buildExpandedContent(
              group,
              sharedAssets: sharedAssets,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // 멤버 색상/별명 매핑 (공유 자산 표시용)
  Color _getMemberColor(String? hex) {
    if (hex == null) return AppColors.teal500;
    try {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    } catch (_) {
      return AppColors.teal500;
    }
  }

  Widget _buildExpandedContent(
    AssetGroup group, {
    List<Map<String, dynamic>> sharedAssets = const [],
  }) {
    // 멤버 정보 캐시 (그룹 선택 시 _myGroups에서 가져옴)
    final currentGroup = _myGroups
        .where((g) => g['id'] == _selectedGroupId)
        .firstOrNull;
    final members =
        (currentGroup?['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final memberNicknames = <String, String>{};
    final memberColors = <String, String?>{};
    for (final m in members) {
      final uid = (m['user'] as Map?)?['id'] as String? ?? '';
      memberNicknames[uid] =
          m['nickname'] as String? ??
          (m['user'] as Map?)?['name'] as String? ??
          '';
      memberColors[uid] = m['color'] as String?;
    }

    return Column(
      children: [
        Divider(
          height: 1,
          color: AppColors.gray200,
          indent: AppSpacing.cardPadding,
          endIndent: AppSpacing.cardPadding,
        ),
        // 내 자산 항목
        ...group.items.map((item) => _buildAssetItem(item, group)),
        // 공유받은 자산 항목
        ...sharedAssets.map((raw) {
          final name = raw['name'] as String? ?? '';
          final history = raw['valueHistory'] as List<dynamic>? ?? [];
          final value = history.isNotEmpty
              ? (history.first['value'] as num).toInt()
              : 0;
          final ownerId =
              raw['userId'] as String? ?? raw['user_id'] as String? ?? '';
          final ownerName =
              memberNicknames[ownerId] ??
              (raw['user'] as Map?)?['name'] as String? ??
              '';
          final ownerColor = _getMemberColor(memberColors[ownerId]);

          return Container(
            decoration: BoxDecoration(
              color: ownerColor.withValues(alpha: 0.04),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ownerColor.withValues(alpha: 0.1),
                                borderRadius: AppRadius.fullAll,
                              ),
                              child: Text(
                                ownerName,
                                style: AppTypography.caption.copyWith(
                                  color: ownerColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(formatKoreanWon(value), style: AppTypography.amountSmall),
              ],
            ),
          );
        }),
        // Update button
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            AppSpacing.sm,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
          ),
          child: AlButton(
            label: '이번 달 업데이트',
            variant: AlButtonVariant.secondary,
            icon: Icon(
              LucideIcons.refreshCw,
              size: 16,
              color: AppColors.gray700,
            ),
            onPressed: () => _showUpdateSheet(group),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetItem(AssetItem item, AssetGroup group) {
    return GestureDetector(
      onTap: () => _showEditAssetSheet(item, group),
      onLongPress: () => _showAssetActionSheet(item, group),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${item.lastUpdated} 업데이트',
                        style: AppTypography.caption,
                      ),
                      if (item.editedBy != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _buildEditorBadge(item.editedBy!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Value and change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatKoreanWon(item.currentValue),
                  style: AppTypography.label,
                ),
                SizedBox(height: 2),
                if (item.changePercent != 0)
                  AlChangeIndicator.percent(
                    percent: item.changePercent,
                    iconSize: 12,
                    fontSize: 11,
                  )
                else
                  Text('전월 동일', style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBadge(String name) {
    final isMe = name == '나';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMe ? LucideIcons.user : LucideIcons.users,
          size: 10,
          color: isMe ? AppColors.gray400 : AppColors.blue600,
        ),
        SizedBox(width: 3),
        Text(
          name,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: isMe ? AppColors.gray400 : AppColors.blue600,
          ),
        ),
      ],
    );
  }

  // ─── Add Asset Button ────────────────────────────────────────────────

  Widget _buildAddAssetButton() {
    return GestureDetector(
      onTap: _showAddAssetSheet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gray300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: AppRadius.lgAll,
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(LucideIcons.plus, size: 24, color: AppColors.gray400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '새 자산 추가',
              style: AppTypography.label.copyWith(color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

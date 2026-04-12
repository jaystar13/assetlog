import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_confirm_dialog.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_change_indicator.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/notifiers/asset_notifier.dart';
import '../core/providers.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format_korean_won.dart';
import '../utils/date_format.dart';
import '../utils/snackbar_helper.dart';

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
      _selectedMonth = DateTime(
        _selectedMonth.month == 1
            ? _selectedMonth.year - 1
            : _selectedMonth.year,
        _selectedMonth.month == 1 ? 12 : _selectedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.month == 12
            ? _selectedMonth.year + 1
            : _selectedMonth.year,
        _selectedMonth.month == 12 ? 1 : _selectedMonth.month + 1,
      );
    });
  }

  // ─── 새 자산 추가 Bottom Sheet ──────────────────────────────────────
  void _showAddAssetSheet() async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final groups = ref.read(assetNotifierProvider(_monthKey)).valueOrNull ?? [];
    String selectedGroup = groups.isNotEmpty ? groups.first.id : 'cash';

    // 공유 그룹 목록 가져오기
    List<Map<String, dynamic>> shareGroups = [];
    try {
      shareGroups = await ref.read(shareGroupServiceProvider).getMyGroups();
    } catch (_) {}
    final selectedShareGroupIds = <String>{};
    if (!mounted) return;

    AlBottomSheet.show(
      context: context,
      title: '새 자산 추가',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 자산 그룹 선택
              Text('자산 유형', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: AppRadius.smAll,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedGroup,
                    isExpanded: true,
                    icon: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.gray500,
                    ),
                    style: AppTypography.bodyLarge,
                    items: groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Row(
                              children: [
                                Icon(g.icon, size: 18, color: g.colors.text),
                                const SizedBox(width: AppSpacing.sm),
                                Text(g.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedGroup = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 자산명
              AlInput(
                label: '자산명',
                placeholder: '예: 서울 아파트, S&P 500 ETF 등',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 현재 가치
              AlInput(
                label: '현재 가치 (원)',
                placeholder: '금액을 입력하세요',
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                prefixIcon: Icon(
                  LucideIcons.banknote,
                  size: 16,
                  color: AppColors.gray500,
                ),
              ),
              // 공유 그룹 선택
              if (shareGroups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('공유 그룹', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: shareGroups.map((g) {
                    final gId = g['id'] as String;
                    final gName = g['name'] as String;
                    final sel = selectedShareGroupIds.contains(gId);
                    return GestureDetector(
                      onTap: () => setSheetState(() {
                        if (sel) {
                          selectedShareGroupIds.remove(gId);
                        } else {
                          selectedShareGroupIds.add(gId);
                        }
                      }),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.emerald50 : AppColors.gray50,
                          borderRadius: AppRadius.fullAll,
                          border: Border.all(
                            color: sel
                                ? AppColors.emerald500
                                : AppColors.gray200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sel
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              size: 14,
                              color: sel
                                  ? AppColors.emerald600
                                  : AppColors.gray400,
                            ),
                            SizedBox(width: 6),
                            Text(
                              gName,
                              style: AppTypography.bodySmall.copyWith(
                                color: sel
                                    ? AppColors.emerald700
                                    : AppColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // 추가 버튼
              AlButton(
                label: '자산 추가',
                icon: Icon(LucideIcons.plus, size: 18, color: Colors.white),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final valueText = valueController.text.trim();

                  if (name.isEmpty) {
                    showErrorSnackBar(context, '자산명을 입력해 주세요');
                    return;
                  }
                  if (valueText.isEmpty) {
                    showErrorSnackBar(context, '금액을 입력해 주세요');
                    return;
                  }

                  final value = CurrencyInputFormatter.parse(valueText);
                  if (value == null) {
                    showErrorSnackBar(context, '올바른 금액을 입력해 주세요');
                    return;
                  }

                  final isDebt = selectedGroup == 'loans';
                  final actualValue = isDebt ? -value.abs() : value;

                  Navigator.of(context).pop();

                  final notifier = ref.read(
                    assetNotifierProvider(_monthKey).notifier,
                  );
                  await notifier.addAsset(
                    categoryId: selectedGroup,
                    name: name,
                    initialValue: actualValue,
                    shareGroupIds: selectedShareGroupIds.isNotEmpty
                        ? selectedShareGroupIds.toList()
                        : null,
                  );

                  _expandedGroups.add(selectedGroup);
                  if (mounted) showSuccessSnackBar(context, '자산이 추가되었습니다');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── 개별 자산 수정 Bottom Sheet ─────────────────────────────────────
  void _showEditAssetSheet(AssetItem item, AssetGroup group) {
    final nameController = TextEditingController(text: item.name);
    final valueController = TextEditingController(
      text: item.currentValue.abs().toString(),
    );

    AlBottomSheet.show(
      context: context,
      title: '자산 수정',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 자산 유형 표시 (읽기 전용)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: group.colors.light,
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    Icon(group.icon, size: 18, color: group.colors.text),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      group.name,
                      style: AppTypography.label.copyWith(
                        color: group.colors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 자산명
              AlInput(
                label: '자산명',
                placeholder: '예: 서울 아파트',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 현재 가치
              AlInput(
                label: '현재 가치 (원)',
                placeholder: '금액을 입력하세요',
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                prefixIcon: Icon(
                  LucideIcons.banknote,
                  size: 16,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 수정 버튼
              AlButton(
                label: '수정',
                icon: Icon(LucideIcons.pencil, size: 18, color: Colors.white),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final valueText = valueController.text.trim();

                  if (name.isEmpty) {
                    showErrorSnackBar(context, '자산명을 입력해 주세요');
                    return;
                  }
                  if (valueText.isEmpty) {
                    showErrorSnackBar(context, '금액을 입력해 주세요');
                    return;
                  }

                  final value = CurrencyInputFormatter.parse(valueText);
                  if (value == null) {
                    showErrorSnackBar(context, '올바른 금액을 입력해 주세요');
                    return;
                  }

                  final isDebt = group.id == 'loans';
                  final actualValue = isDebt
                      ? -value.abs().toInt()
                      : value.toInt();

                  Navigator.of(context).pop();

                  final month = _monthKey;
                  await ref
                      .read(assetNotifierProvider(_monthKey).notifier)
                      .updateAssetValue(
                        assetId: item.id,
                        month: month,
                        value: actualValue,
                      );

                  if (mounted) showSuccessSnackBar(context, '자산이 수정되었습니다');
                },
              ),
            ],
          );
        },
      ),
    );
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
    final controllers = <String, TextEditingController>{};
    for (final item in group.items) {
      controllers[item.id] = TextEditingController(
        text: item.currentValue.abs().toString(),
      );
    }

    AlBottomSheet.show(
      context: context,
      title: '${group.name} 업데이트',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...group.items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name, style: AppTypography.label),
                          Text(
                            '현재: ${formatKoreanWon(item.currentValue)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AlInput(
                        placeholder: '새 금액을 입력하세요',
                        controller: controllers[item.id],
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.sm),
              AlButton(
                label: '업데이트',
                onPressed: () async {
                  Navigator.of(context).pop();

                  final month = _monthKey;
                  final notifier = ref.read(
                    assetNotifierProvider(_monthKey).notifier,
                  );
                  final isDebt = group.id == 'loans';

                  for (final item in group.items) {
                    final text = controllers[item.id]?.text ?? '';
                    final value = CurrencyInputFormatter.parse(text);
                    if (value != null) {
                      final actualValue = isDebt ? -value.abs() : value;
                      await notifier.updateAssetValue(
                        assetId: item.id,
                        month: month,
                        value: actualValue,
                      );
                    }
                  }

                  if (mounted) showSuccessSnackBar(context, '자산이 업데이트되었습니다');
                },
              ),
            ],
          );
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
    } catch (_) {}
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
    } catch (_) {}
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
                _buildPieChartCard(groups),
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

  // ─── Pie Chart Card ──────────────────────────────────────────────────

  Widget _buildPieChartCard(List<AssetGroup> groups) {
    // Only include positive-value groups for the composition chart
    final positiveGroups = groups.where((g) => g.totalValue > 0).toList();
    final totalPositive = positiveGroups.fold<num>(
      0,
      (sum, g) => sum + g.totalValue,
    );

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('자산 구성', style: AppTypography.heading3),
              Row(
                children: [
                  Text(
                    '총 ${formatKoreanWon(groups.fold<num>(0, (sum, g) => sum + g.totalValue))}',
                    style: AppTypography.label,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: positiveGroups.map((group) {
                        return PieChartSectionData(
                          value: group.totalValue.toDouble(),
                          color: group.colors.bg,
                          radius: 32,
                          title: '',
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: positiveGroups.map((group) {
                    final percent = totalPositive > 0
                        ? (group.totalValue / totalPositive * 100)
                        : 0.0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: group.colors.bg,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            group.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
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

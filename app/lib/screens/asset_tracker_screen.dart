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
import '../utils/currency_input_formatter.dart';
import '../utils/format_korean_won.dart';
import '../utils/snackbar_helper.dart';

class AssetTrackerScreen extends ConsumerStatefulWidget {
  const AssetTrackerScreen({super.key});

  @override
  ConsumerState<AssetTrackerScreen> createState() => _AssetTrackerScreenState();
}

class _AssetTrackerScreenState extends ConsumerState<AssetTrackerScreen> {
  DateTime _selectedMonth = DateTime.now();
  final Set<String> _expandedGroups = {};

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

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
  void _showAddAssetSheet() {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final groups = ref.read(assetNotifierProvider(_monthKey)).valueOrNull ?? [];
    String selectedGroup = groups.isNotEmpty ? groups.first.id : 'cash';

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
              SizedBox(height: AppSpacing.sm),
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
                    icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.gray500),
                    style: AppTypography.bodyLarge,
                    items: groups
                        .map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Row(
                                children: [
                                  Icon(g.icon, size: 18, color: g.colors.text),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(g.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedGroup = val);
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // 자산명
              AlInput(
                label: '자산명',
                placeholder: '예: 서울 아파트, S&P 500 ETF 등',
                controller: nameController,
              ),
              SizedBox(height: AppSpacing.lg),

              // 현재 가치
              AlInput(
                label: '현재 가치 (원)',
                placeholder: '금액을 입력하세요',
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                prefixIcon: Icon(LucideIcons.banknote, size: 16, color: AppColors.gray500),
              ),
              SizedBox(height: AppSpacing.xl),

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

                  final notifier = ref.read(assetNotifierProvider(_monthKey).notifier);
                  await notifier.addAsset(
                    categoryId: selectedGroup,
                    name: name,
                    initialValue: actualValue,
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
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      group.name,
                      style: AppTypography.label.copyWith(
                        color: group.colors.text,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // 자산명
              AlInput(
                label: '자산명',
                placeholder: '예: 서울 아파트',
                controller: nameController,
              ),
              SizedBox(height: AppSpacing.lg),

              // 현재 가치
              AlInput(
                label: '현재 가치 (원)',
                placeholder: '금액을 입력하세요',
                controller: valueController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                prefixIcon: Icon(LucideIcons.banknote, size: 16, color: AppColors.gray500),
              ),
              SizedBox(height: AppSpacing.xl),

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
                  final actualValue = isDebt ? -value.abs().toInt() : value.toInt();

                  Navigator.of(context).pop();

                  final month = _monthKey;
                  await ref.read(assetNotifierProvider(_monthKey).notifier).updateAssetValue(
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

  // ─── 개별 자산 삭제 확인 다이얼로그 ─────────────────────────────────
  void _showDeleteAssetDialog(AssetItem item, AssetGroup group) {
    AlConfirmDialog.show(
      context: context,
      title: '자산 삭제',
      message: "'${item.name}' 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
      onConfirm: () async {
        await ref.read(assetNotifierProvider(_monthKey).notifier).deleteAsset(item.id);
        if (mounted) showSuccessSnackBar(context, "'${item.name}' 항목이 삭제되었습니다");
      },
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
                      SizedBox(height: AppSpacing.sm),
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
              SizedBox(height: AppSpacing.sm),
              AlButton(
                label: '업데이트',
                onPressed: () async {
                  Navigator.of(context).pop();

                  final month = _monthKey;
                  final notifier = ref.read(assetNotifierProvider(_monthKey).notifier);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(title: '자산 현황', subtitle: '나의 자산을 카테고리별로 관리하세요'),

          // Month selector
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          // Scrollable content
          Expanded(
            child: ref.watch(assetNotifierProvider(_monthKey)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('데이터를 불러올 수 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500))),
              data: (groups) => SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.screenPadding,
                  right: AppSpacing.screenPadding,
                  bottom: AppSpacing.bottomNavSafeArea,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSpacing.lg),
                    _buildPieChartCard(groups),
                    SizedBox(height: AppSpacing.sectionGap),
                    ...groups.map((group) => Padding(
                          key: ValueKey(group.id),
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _buildAssetGroupCard(group),
                        )),
                    SizedBox(height: AppSpacing.sm),
                    _buildAddAssetButton(),
                    SizedBox(height: AppSpacing.sectionGap),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
    );
  }

  // ─── Pie Chart Card ──────────────────────────────────────────────────

  Widget _buildPieChartCard(List<AssetGroup> groups) {
    // Only include positive-value groups for the composition chart
    final positiveGroups =
        groups.where((g) => g.totalValue > 0).toList();
    final totalPositive =
        positiveGroups.fold<num>(0, (sum, g) => sum + g.totalValue);

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
          SizedBox(height: AppSpacing.xl),
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
                SizedBox(width: AppSpacing.xl),
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
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            group.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray700,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
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

  Widget _buildAssetGroupCard(AssetGroup group) {
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
                  SizedBox(width: AppSpacing.md),
                  // Name and item count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: AppTypography.label),
                        SizedBox(height: 2),
                        Text(
                          '${group.items.length}개 항목',
                          style: AppTypography.bodySmall,
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
                  SizedBox(width: AppSpacing.sm),
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
            secondChild: _buildExpandedContent(group),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(AssetGroup group) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: AppColors.gray200,
          indent: AppSpacing.cardPadding,
          endIndent: AppSpacing.cardPadding,
        ),
        // Individual asset items
        ...group.items.map((item) => _buildAssetItem(item, group)),
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
            icon: Icon(LucideIcons.refreshCw, size: 16, color: AppColors.gray700),
            onPressed: () => _showUpdateSheet(group),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetItem(AssetItem item, AssetGroup group) {
    return GestureDetector(
      onTap: () => _showEditAssetSheet(item, group),
      onLongPress: () => _showDeleteAssetDialog(item, group),
      child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: group.colors.bg,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Name and last updated
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gray900,
                )),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${item.lastUpdated} 업데이트',
                      style: AppTypography.caption,
                    ),
                    if (item.editedBy != null) ...[
                      SizedBox(width: AppSpacing.sm),
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
            SizedBox(height: AppSpacing.sm),
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

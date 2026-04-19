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
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/notifiers/transaction_notifier.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';
import '../utils/date_format.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/cashflow/manual_entry_form.dart';

/// 공유 그룹의 거래 데이터를 가져오는 Provider.
/// 파라미터: 'groupId_YYYY-MM' 형식의 키.
final _sharedTransactionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, key) async {
  final parts = key.split('_');
  if (parts.length < 2) return [];
  final groupId = parts[0];
  final month = parts[1];
  return ref
      .watch(shareGroupServiceProvider)
      .getGroupTransactions(groupId, month: month);
});

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  DateTime _selectedMonth = DateTime.now();

  // 그룹 전환 (null = 내 데이터)
  String? _selectedGroupId;
  String _selectedGroupName = '나';
  List<Map<String, dynamic>> _myGroups = [];
  bool _groupsLoaded = false;

  // 필터
  TransactionType? _txFilter;

  // 카테고리 그룹 펼침 상태 (1단계: 카테고리)
  final Set<String> _expandedGroups = {};
  // 세부분류 집계 펼침 상태 (2단계: 세부분류 — 개별 이력 보기)
  final Set<String> _expandedSubGroups = {};

  // 다중 선택 모드
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  // 수기 입력 시트 재진입 방지
  bool _isManualEntrySheetOpen = false;
  // 거래 수정 시트 재진입 방지
  bool _isEditEntrySheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  String get _monthKey => toMonthKey(_selectedMonth);

  bool get _isGroupMode => _selectedGroupId != null;

  Future<void> _loadGroups() async {
    if (_groupsLoaded) return;
    _groupsLoaded = true;
    try {
      final groups = await ref.read(shareGroupServiceProvider).getMyGroups();
      if (mounted) setState(() => _myGroups = groups);
    } catch (_) {
      /* 공유 데이터 로딩 실패 시 무시 */
    }
  }

  void _toggleSelectMode({List<String>? allGroupKeys}) {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIds.clear();
      if (_isSelectMode && allGroupKeys != null) {
        _expandedGroups.addAll(allGroupKeys);
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Transaction> filtered) {
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(filtered.map((t) => t.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    AlConfirmDialog.show(
      context: context,
      title: '일괄 삭제',
      message: '선택한 $count건의 거래를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      onConfirm: () async {
        try {
          final notifier =
              ref.read(transactionNotifierProvider(_monthKey).notifier);
          final deleted = await notifier.batchDeleteTransactions(
            _selectedIds.toList(),
          );
          if (mounted) {
            setState(() {
              _isSelectMode = false;
              _selectedIds.clear();
            });
            showSuccessSnackBar(context, '$deleted건의 거래가 삭제되었습니다');
          }
        } catch (e) {
          if (mounted) showErrorSnackBar(context, '삭제 실패: $e');
        }
      },
    );
  }

  List<Transaction> _filter(List<Transaction> txs) => _txFilter == null
      ? txs
      : txs.where((t) => t.type == _txFilter).toList();

  int _totalIncome(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  int _totalExpense(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _showManualEntrySheet() async {
    if (_isManualEntrySheetOpen) return;
    _isManualEntrySheetOpen = true;
    try {
      List<Map<String, dynamic>> groups = [];
      try {
        groups = await ref.read(shareGroupServiceProvider).getMyGroups();
      } catch (_) {/* ignore */}
      if (!mounted) return;

      await AlBottomSheet.show(
        context: context,
        title: '수기 입력',
        child: ManualEntryForm(
          targetMonth: _monthKey,
          shareGroups: groups,
          onSubmit: (entry) async {
            Navigator.of(context).pop();
            final shareGroupIds =
                (entry['shareGroupIds'] as List<String>?) ?? [];
            try {
              await ref
                  .read(transactionNotifierProvider(_monthKey).notifier)
                  .addTransaction(
                    type: entry['type'] as String,
                    targetMonth: entry['targetMonth'] as String,
                    category: entry['category'] as String,
                    subCategory: entry['subCategory'] as String,
                    amount: entry['amount'] as int,
                    note: entry['note'] as String?,
                    shareGroupIds:
                        shareGroupIds.isNotEmpty ? shareGroupIds : null,
                  );
              if (mounted) showSuccessSnackBar(context, '저장되었습니다');
            } catch (e) {
              if (mounted) showErrorSnackBar(context, '저장 실패: $e');
            }
          },
        ),
      );
    } finally {
      _isManualEntrySheetOpen = false;
    }
  }

  void _showEditEntrySheet(Transaction tx) async {
    if (_isEditEntrySheetOpen) return;
    _isEditEntrySheetOpen = true;
    try {
      List<Map<String, dynamic>> groups = [];
      List<String> currentGroupIds = [];
      try {
        final service = ref.read(shareGroupServiceProvider);
        groups = await service.getMyGroups();
        currentGroupIds =
            await service.getItemSharedGroups('transaction', tx.id);
      } catch (_) {/* ignore */}
      if (!mounted) return;

      await AlBottomSheet.show(
        context: context,
        title: '거래 수정',
        child: ManualEntryForm(
          targetMonth: tx.targetMonth,
          initialData: tx.toMap(),
          shareGroups: groups,
          initialShareGroupIds: currentGroupIds,
          onSubmit: (updated) async {
            Navigator.of(context).pop();
            try {
              await ref
                  .read(transactionNotifierProvider(_monthKey).notifier)
                  .updateTransaction(tx.id, {
                'amount': updated['amount'],
                'note': updated['note'],
              });
              final shareGroupIds =
                  (updated['shareGroupIds'] as List<String>?) ?? [];
              if (shareGroupIds.isNotEmpty) {
                try {
                  await ref.read(shareGroupServiceProvider).shareItems(
                    shareGroupIds.first,
                    [
                      {'itemType': 'transaction', 'itemId': tx.id},
                    ],
                  );
                } catch (_) {/* ignore */}
              }
              if (mounted) showSuccessSnackBar(context, '수정되었습니다');
            } catch (e) {
              if (mounted) showErrorSnackBar(context, '수정 실패: $e');
            }
          },
        ),
      );
    } finally {
      _isEditEntrySheetOpen = false;
    }
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
                  ? Icon(LucideIcons.check,
                      size: 18, color: AppColors.emerald600)
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
              final isSelected = _selectedGroupId == gId;
              return ListTile(
                leading: Icon(
                  LucideIcons.users,
                  color:
                      isSelected ? AppColors.emerald600 : AppColors.gray500,
                ),
                title: Text(displayName, style: AppTypography.bodyLarge),
                trailing: isSelected
                    ? Icon(LucideIcons.check,
                        size: 18, color: AppColors.emerald600)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '수입/지출 관리',
            subtitle: '매월 카테고리별 합계를 기록하세요',
            action: _myGroups.isNotEmpty ? _buildGroupChip() : null,
          ),
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildGroupChip() {
    return GestureDetector(
      onTap: _showGroupSelector,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isGroupMode ? AppColors.emerald50 : AppColors.gray50,
          borderRadius: AppRadius.fullAll,
          border: Border.all(
            color:
                _isGroupMode ? AppColors.emerald500 : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isGroupMode ? LucideIcons.users : LucideIcons.user,
                size: 14,
                color: _isGroupMode
                    ? AppColors.emerald600
                    : AppColors.gray600),
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
            Icon(LucideIcons.chevronDown,
                size: 12, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  /// 현재 그룹 모드에서의 공유 거래 목록
  List<Map<String, dynamic>> get _sharedTransactions {
    if (!_isGroupMode) return [];
    final key = '${_selectedGroupId}_$_monthKey';
    return ref.watch(_sharedTransactionsProvider(key)).valueOrNull ?? [];
  }

  Widget _buildContent() {
    return ref
        .watch(transactionNotifierProvider(_monthKey))
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
                      ref.invalidate(transactionNotifierProvider(_monthKey)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (transactions) {
            final filtered = _filter(transactions);
            final income = _totalIncome(transactions);
            final expense = _totalExpense(transactions);
            final balance = income - expense;
            final expenseRatio = income > 0 ? expense / income : 0.0;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: AppSpacing.bottomNavSafeArea,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _buildMonthlySummaryCard(
                    income: income,
                    expense: expense,
                    balance: balance,
                    expenseRatio: expenseRatio,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  AlButton(
                    label: '수기 입력',
                    onPressed: _showManualEntrySheet,
                    icon:
                        Icon(LucideIcons.plus, size: 18, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  _buildListHeader(filtered),
                  const SizedBox(height: AppSpacing.md),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ..._buildCategoryGroups(filtered),
                  if (_isSelectMode && _selectedIds.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: AlButton(
                        label: '${_selectedIds.length}건 삭제',
                        variant: AlButtonVariant.danger,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed: _deleteSelected,
                      ),
                    ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildListHeader(List<Transaction> filtered) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('내역', style: AppTypography.heading3),
        Row(
          children: [
            if (_isSelectMode && filtered.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _selectAll(filtered),
                child: Text(
                  _selectedIds.length == filtered.length ? '전체 해제' : '전체 선택',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.emerald600),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            if (filtered.isNotEmpty)
              GestureDetector(
                onTap: () => _toggleSelectMode(
                  allGroupKeys: _getGroupKeys(filtered),
                ),
                child: Text(
                  _isSelectMode ? '취소' : '선택',
                  style: AppTypography.bodySmall.copyWith(
                    color: _isSelectMode
                        ? AppColors.gray500
                        : AppColors.emerald600,
                  ),
                ),
              ),
            if (!_isSelectMode) ...[
              const SizedBox(width: AppSpacing.md),
              _buildTxFilterSegment(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 48, color: AppColors.gray300),
            const SizedBox(height: AppSpacing.md),
            Text(
              '내역이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '수기 입력으로 카테고리별 합계를 기록해 보세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxFilterSegment() {
    Widget segment(TransactionType? value, String label) {
      final isSelected = _txFilter == value;
      return GestureDetector(
        onTap: () => setState(() => _txFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emerald600 : Colors.transparent,
            borderRadius: AppRadius.fullAll,
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.gray500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(null, '전체'),
          segment(TransactionType.income, '수입'),
          segment(TransactionType.expense, '지출'),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard({
    required int income,
    required int expense,
    required int balance,
    required double expenseRatio,
  }) {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월간 요약', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수입', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(income),
                      style: AppTypography.amountMedium.copyWith(
                        color: AppColors.green600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지출', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(expense),
                      style: AppTypography.amountMedium.copyWith(
                        color: AppColors.red600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: expenseRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.green100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.red600),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('잔액', style: AppTypography.bodyMedium),
              Text(
                formatKoreanWon(balance),
                style: AppTypography.amountSmall.copyWith(
                  color: balance >= 0
                      ? AppColors.emerald600
                      : AppColors.red600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 공유 거래의 소유자 정보 (txId → {name, nickname, color})
  final Map<String, ({String name, String? nickname, String? color})>
      _sharedTxOwners = {};

  // 작성자별 색상 매핑
  static const _ownerColors = [
    AppColors.teal500,
    AppColors.purple600,
    AppColors.blue600,
    Color(0xFFF59E0B),
    AppColors.red600,
  ];
  final Map<String, Color> _ownerColorMap = {};

  Color _getOwnerColor(String ownerName) {
    return _ownerColorMap.putIfAbsent(ownerName, () {
      return _ownerColors[_ownerColorMap.length % _ownerColors.length];
    });
  }

  List<String> _getGroupKeys(List<Transaction> transactions) {
    final keys = <String>[];
    for (final tx in transactions) {
      final key = '${tx.type.value}_${tx.category}';
      if (!keys.contains(key)) keys.add(key);
    }
    return keys;
  }

  /// 카테고리별 그룹핑 (1단계 카테고리 기준)
  List<Widget> _buildCategoryGroups(List<Transaction> myTransactions) {
    // 그룹 모드일 때 공유 거래를 합침
    final transactions = [...myTransactions];
    _sharedTxOwners.clear();

    if (_isGroupMode && _sharedTransactions.isNotEmpty) {
      for (final raw in _sharedTransactions) {
        final txId = raw['id'] as String;
        if (myTransactions.any((t) => t.id == txId)) continue;
        try {
          final tx = Transaction.fromMap(raw);
          transactions.add(tx);
          final owner = raw['user'] as Map<String, dynamic>? ?? {};
          _sharedTxOwners[txId] = (
            name: owner['name'] as String? ?? '',
            nickname: raw['_nickname'] as String?,
            color: raw['_color'] as String?,
          );
        } catch (_) {/* ignore */}
      }
    }

    if (transactions.isEmpty) return [];

    // type 분리 후, type별로 category 그룹핑
    final incomes = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final showIncome =
        _txFilter == null || _txFilter == TransactionType.income;
    final showExpense =
        _txFilter == null || _txFilter == TransactionType.expense;

    final widgets = <Widget>[];

    if (showIncome && incomes.isNotEmpty) {
      widgets.add(_buildSectionLabel('수입', AppColors.green600));
      widgets.addAll(_groupByCategory(incomes, AppColors.emerald600));
    }
    if (showExpense && expenses.isNotEmpty) {
      widgets.add(_buildSectionLabel('지출', AppColors.red600));
      widgets.addAll(_groupByCategory(expenses, AppColors.red600));
    }
    return widgets;
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: color),
      ),
    );
  }

  /// type별로 필터된 거래들을 1단계 카테고리 기준으로 묶어 카드 목록을 반환
  List<Widget> _groupByCategory(List<Transaction> items, Color color) {
    // 카테고리 출현 순서 (incomeCategories/expenseCategories의 정의 순서)
    final grouped = <String, List<Transaction>>{};
    for (final tx in items) {
      grouped.putIfAbsent(tx.category, () => []).add(tx);
    }

    // 공식 카테고리 순서대로 정렬, 그 외는 뒤에
    final orderedKeys = <String>[
      ...incomeCategories.where(grouped.containsKey),
      ...expenseCategories.where(grouped.containsKey),
    ];
    for (final k in grouped.keys) {
      if (!orderedKeys.contains(k)) orderedKeys.add(k);
    }

    return orderedKeys.map((cat) {
      final list = grouped[cat]!;
      final groupKey = '${list.first.type.value}_$cat';
      final total = list.fold<int>(0, (s, t) => s + t.amount);
      return _buildCategoryCard(groupKey, cat, list, total, color);
    }).toList();
  }

  Widget _buildCategoryCard(
    String groupKey,
    String category,
    List<Transaction> items,
    int total,
    Color color,
  ) {
    final isExpanded = _expandedGroups.contains(groupKey) || _isSelectMode;
    final myCount =
        items.where((t) => !_sharedTxOwners.containsKey(t.id)).length;
    final sharedCount = items.length - myCount;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: AlCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: _isSelectMode
                  ? null
                  : () => setState(() {
                        if (_expandedGroups.contains(groupKey)) {
                          _expandedGroups.remove(groupKey);
                        } else {
                          _expandedGroups.add(groupKey);
                        }
                      }),
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Center(
                        child: Text(
                          '${items.length}',
                          style: AppTypography.label.copyWith(color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category, style: AppTypography.label),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Text('$myCount건', style: AppTypography.caption),
                              if (sharedCount > 0) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '· 공유 $sharedCount건',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.teal500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatKoreanWon(total),
                      style:
                          AppTypography.amountSmall.copyWith(color: color),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
            AnimatedCrossFade(
              firstChild: SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: AppColors.gray100),
                  ..._buildSubCategoryAggregates(groupKey, items, color),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  /// 카테고리 카드 내부: 세부분류별 집계 행 + (펼쳤을 때) 개별 이력
  List<Widget> _buildSubCategoryAggregates(
    String parentKey,
    List<Transaction> items,
    Color color,
  ) {
    final bySub = <String, List<Transaction>>{};
    for (final tx in items) {
      bySub.putIfAbsent(tx.subCategory, () => []).add(tx);
    }

    // 카테고리 이름으로 정의된 세부분류 순서를 추출 (최초 tx 기준)
    final canonicalSubs =
        categorySubCategoryMap[items.first.category] ?? const <String>[];
    final orderedSubs = <String>[
      ...canonicalSubs.where(bySub.containsKey),
    ];
    for (final s in bySub.keys) {
      if (!orderedSubs.contains(s)) orderedSubs.add(s);
    }

    final widgets = <Widget>[];
    for (int i = 0; i < orderedSubs.length; i++) {
      final sub = orderedSubs[i];
      final list = bySub[sub]!;
      final subKey = '${parentKey}_$sub';
      final subTotal = list.fold<int>(0, (s, t) => s + t.amount);
      final subExpanded =
          _expandedSubGroups.contains(subKey) || _isSelectMode;

      widgets.add(_buildSubCategoryAggregateRow(
        subKey: subKey,
        subCategory: sub,
        entries: list,
        total: subTotal,
        expanded: subExpanded,
        color: color,
      ));

      // 펼친 경우 개별 이력 노출
      widgets.add(AnimatedCrossFade(
        firstChild: SizedBox.shrink(),
        secondChild: Column(
          children: list.map(_buildEntryRow).toList(),
        ),
        crossFadeState: subExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: Duration(milliseconds: 200),
      ));

      if (i < orderedSubs.length - 1) {
        widgets.add(Divider(height: 1, color: AppColors.gray100));
      }
    }
    return widgets;
  }

  Widget _buildSubCategoryAggregateRow({
    required String subKey,
    required String subCategory,
    required List<Transaction> entries,
    required int total,
    required bool expanded,
    required Color color,
  }) {
    final isIncome = entries.first.type == TransactionType.income;
    return InkWell(
      onTap: _isSelectMode
          ? null
          : () => setState(() {
                if (_expandedSubGroups.contains(subKey)) {
                  _expandedSubGroups.remove(subKey);
                } else {
                  _expandedSubGroups.add(subKey);
                }
              }),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(subCategory, style: AppTypography.bodyMedium),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${entries.length}건',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatKoreanWon(total)}',
              style: AppTypography.bodyMedium.copyWith(
                color: isIncome ? AppColors.green600 : AppColors.red600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: Duration(milliseconds: 200),
              child: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 입력 이력 행 (세부분류 집계 아래에 표시)
  Widget _buildEntryRow(Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    final isShared = _sharedTxOwners.containsKey(tx.id);
    final ownerInfo = _sharedTxOwners[tx.id];
    final ownerName = ownerInfo?.nickname ?? ownerInfo?.name;
    final ownerColor = ownerInfo?.color != null
        ? Color(int.parse('FF${ownerInfo!.color!.substring(1)}', radix: 16))
        : (isShared && ownerName != null
            ? _getOwnerColor(ownerName)
            : AppColors.teal500);
    final note = tx.note ?? '';

    return GestureDetector(
      onTap: _isSelectMode
          ? (isShared ? null : () => _toggleSelection(tx.id))
          : (isShared ? null : () => _showEditEntrySheet(tx)),
      onLongPress: (_isSelectMode || isShared)
          ? null
          : () {
              AlConfirmDialog.show(
                context: context,
                title: '삭제',
                message:
                    "'${tx.category} - ${tx.subCategory}' 입력 1건을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
                onConfirm: () async {
                  await ref
                      .read(transactionNotifierProvider(_monthKey).notifier)
                      .deleteTransaction(tx.id);
                  if (mounted) {
                    showSuccessSnackBar(context, '삭제되었습니다');
                  }
                },
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: isShared
              ? ownerColor.withValues(alpha: 0.04)
              : AppColors.gray50,
          border: Border(
            top: BorderSide(color: AppColors.gray100, width: 0.5),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.cardPadding + AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.cardPadding,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (_isSelectMode && !isShared) ...[
              Icon(
                _selectedIds.contains(tx.id)
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 18,
                color: _selectedIds.contains(tx.id)
                    ? AppColors.emerald600
                    : AppColors.gray300,
              ),
              const SizedBox(width: AppSpacing.md),
            ] else ...[
              Icon(
                LucideIcons.cornerDownRight,
                size: 12,
                color: AppColors.gray300,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      note.isEmpty ? '(비고 없음)' : note,
                      style: AppTypography.bodySmall.copyWith(
                        color: note.isEmpty
                            ? AppColors.gray400
                            : AppColors.gray700,
                        fontStyle: note.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isShared && ownerName != null) ...[
                    const SizedBox(width: AppSpacing.sm),
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
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatKoreanWon(tx.amount)}',
              style: AppTypography.bodySmall.copyWith(
                color: isIncome ? AppColors.green600 : AppColors.red600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

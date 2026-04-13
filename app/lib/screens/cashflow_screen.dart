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
import '../repositories/repositories.dart';
import '../utils/format_korean_won.dart';
import '../utils/date_format.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/cashflow/manual_entry_form.dart';
import '../widgets/cashflow/import_sheet_content.dart';

/// 공유 그룹의 거래 데이터를 가져오는 Provider.
/// 파라미터: 'groupId_YYYY-MM' 형식의 키.
final _sharedTransactionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, key) async {
  final parts = key.split('_');
  if (parts.length < 2) return [];
  final groupId = parts[0];
  final month = parts[1];
  return ref.watch(shareGroupServiceProvider).getGroupTransactions(groupId, month: month);
});

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  DateTime _selectedMonth = DateTime.now();
  final _cardCompanies = CashflowRepository().getCardCompanies();

  // 그룹 전환 (null = 내 데이터)
  String? _selectedGroupId;
  String _selectedGroupName = '나';
  List<Map<String, dynamic>> _myGroups = [];
  bool _groupsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  // 거래 내역 필터
  TransactionType? _txFilter;

  // 카드 사용 내역 펼침
  bool _showCardUsage = false;

  // 거래 그룹 펼침 상태
  final Set<String> _expandedTxGroups = {};

  // 다중 선택 모드
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectMode({List<String>? allGroupKeys}) {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIds.clear();
      if (_isSelectMode && allGroupKeys != null) {
        _expandedTxGroups.addAll(allGroupKeys);
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
        final notifier = ref.read(
          transactionNotifierProvider(_monthKey).notifier,
        );
        for (final id in _selectedIds) {
          await notifier.deleteTransaction(id);
        }
        if (mounted) {
          setState(() {
            _isSelectMode = false;
            _selectedIds.clear();
          });
          showSuccessSnackBar(context, '$count건의 거래가 삭제되었습니다');
        }
      },
    );
  }

  String get _monthKey => toMonthKey(_selectedMonth);

  List<Transaction> _filterTransactions(List<Transaction> transactions) =>
      _txFilter == null
      ? transactions
      : transactions.where((t) => t.type == _txFilter).toList();

  int _totalIncome(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  int _totalExpense(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

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

  void _showManualEntrySheet() async {
    // 그룹 목록 가져오기
    List<Map<String, dynamic>> groups = [];
    try {
      groups = await ref.read(shareGroupServiceProvider).getMyGroups();
    } catch (_) { /* 공유 데이터 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }

    if (!mounted) return;

    AlBottomSheet.show(
      context: context,
      title: '수기 입력',
      child: ManualEntryForm(
        shareGroups: groups,
        onSubmit: (entry) async {
          Navigator.of(context).pop();
          final shareGroupIds = (entry['shareGroupIds'] as List<String>?) ?? [];
          await ref
              .read(transactionNotifierProvider(_monthKey).notifier)
              .addTransaction(
                type: entry['type'] as String,
                name: entry['name'] as String,
                amount: entry['amount'] as int,
                date: entry['date'] as String,
                category: entry['category'] as String,
                subCategory: entry['subCategory'] as String,
                paymentMethod: entry['paymentMethod'] as String?,
                shareGroupIds: shareGroupIds.isNotEmpty ? shareGroupIds : null,
              );
          if (mounted) showSuccessSnackBar(context, '거래가 추가되었습니다');
        },
      ),
    );
  }

  void _showEditEntrySheet(Transaction tx) async {
    List<Map<String, dynamic>> groups = [];
    List<String> currentGroupIds = [];
    try {
      final service = ref.read(shareGroupServiceProvider);
      groups = await service.getMyGroups();
      currentGroupIds = await service.getItemSharedGroups('transaction', tx.id);
    } catch (_) { /* 공유 데이터 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
    if (!mounted) return;

    AlBottomSheet.show(
      context: context,
      title: '거래 수정',
      child: ManualEntryForm(
        initialData: tx.toMap(),
        shareGroups: groups,
        initialShareGroupIds: currentGroupIds,
        onSubmit: (updated) async {
          Navigator.of(context).pop();
          const allowedFields = {
            'type',
            'name',
            'amount',
            'date',
            'category',
            'subCategory',
            'paymentMethod',
            'targetMonth',
            'isInstallment',
            'installmentMonths',
            'installmentRound',
          };
          final payload = Map<String, dynamic>.fromEntries(
            updated.entries.where((e) => allowedFields.contains(e.key)),
          );
          await ref
              .read(transactionNotifierProvider(_monthKey).notifier)
              .updateTransaction(tx.id, payload);

          // 공유 그룹 변경
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
            } catch (_) { /* 공유 데이터 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
          }

          if (mounted) showSuccessSnackBar(context, '거래가 수정되었습니다');
        },
      ),
    );
  }

  Future<void> _loadGroups() async {
    if (_groupsLoaded) return;
    _groupsLoaded = true;
    try {
      final groups = await ref.read(shareGroupServiceProvider).getMyGroups();
      if (mounted) setState(() => _myGroups = groups);
    } catch (_) { /* 공유 데이터 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
  }

  bool get _isGroupMode => _selectedGroupId != null;

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
              final isSelected = _selectedGroupId == gId;
              return ListTile(
                leading: Icon(
                  LucideIcons.users,
                  color: isSelected ? AppColors.emerald600 : AppColors.gray500,
                ),
                title: Text(displayName, style: AppTypography.bodyLarge),
                trailing: isSelected
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '수입/지출 관리',
            subtitle: '매월 수입과 지출을 관리하세요',
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

          // Month selector
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          // Scrollable content
          Expanded(child: _buildContent()),
        ],
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
            final filtered = _filterTransactions(transactions);
            // 월간 요약은 내 데이터만
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
                    transactions: transactions,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  SmartImportCard(onTap: _showImportSheet),
                  const SizedBox(height: AppSpacing.lg),
                  AlButton(
                    label: '수기 입력',
                    onPressed: _showManualEntrySheet,
                    icon: Icon(LucideIcons.plus, size: 18, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('거래 내역', style: AppTypography.heading3),
                      Row(
                        children: [
                          if (_isSelectMode && filtered.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => _selectAll(filtered),
                              child: Text(
                                _selectedIds.length == filtered.length
                                    ? '전체 해제'
                                    : '전체 선택',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.emerald600,
                                ),
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
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (filtered.isEmpty &&
                      !(_isGroupMode && _sharedTransactions.isNotEmpty))
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              size: 48,
                              color: AppColors.gray300,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '거래 내역이 없습니다',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '수기 입력 또는 명세서 가져오기로 추가해 보세요',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(filtered),
                  // 선택 모드 삭제 바
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
    required List<Transaction> transactions,
  }) {
    // 카드 사용 내역 집계
    final cardTxs = transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.paymentMethod != null &&
              t.paymentMethod!.contains('카드'),
        )
        .toList();
    final Map<String, int> byCard = {};
    for (final tx in cardTxs) {
      byCard[tx.paymentMethod!] = (byCard[tx.paymentMethod!] ?? 0) + tx.amount;
    }
    final sortedCards = byCard.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final cardTotal = sortedCards.fold<int>(0, (sum, e) => sum + e.value);
    final hasCardData = sortedCards.isNotEmpty;

    final cardColors = [
      AppColors.blue600,
      AppColors.emerald500,
      AppColors.purple600,
      Color(0xFFF59E0B),
      AppColors.teal500,
      AppColors.red600,
    ];

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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.red600),
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
                  color: balance >= 0 ? AppColors.emerald600 : AppColors.red600,
                ),
              ),
            ],
          ),

          // 카드 사용 내역 토글
          if (hasCardData) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => setState(() => _showCardUsage = !_showCardUsage),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.gray100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, size: 14, color: AppColors.gray500),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _showCardUsage ? '카드 사용 내역 접기' : '카드 사용 내역 보기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      _showCardUsage
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  children: [
                    ...sortedCards.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final pct = cardTotal > 0 ? entry.value / cardTotal : 0.0;
                      final color = cardColors[idx % cardColors.length];
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Text(
                              formatKoreanWon(entry.value),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${(pct * 100).round()}%',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.gray500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(height: 1, color: AppColors.gray100),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '카드 합계',
                          style: AppTypography.label.copyWith(fontSize: 12),
                        ),
                        Text(
                          formatKoreanWon(cardTotal),
                          style: AppTypography.label.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _showCardUsage
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 250),
            ),
          ],
        ],
      ),
    );
  }

  void _showImportSheet() {
    AlBottomSheet.show(
      context: context,
      title: '명세서 가져오기',
      maxHeightFraction: 0.85,
      child: ImportSheetContent(
        cardCompanies: _cardCompanies,
        targetMonth: _monthKey,
        onImport: ref.read(transactionServiceProvider).importTransactions,
        onSuccess: () => ref.invalidate(transactionNotifierProvider(_monthKey)),
      ),
    );
  }

  /// 그룹핑된 거래를 그룹 키 목록과 함께 반환 (선택 모드에서 사용)
  List<String> _getGroupKeys(List<Transaction> transactions) {
    final keys = <String>[];
    final incomes = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    for (final tx in incomes) {
      final key = 'income_${tx.paymentMethod ?? '기타소득'}';
      if (!keys.contains(key)) keys.add(key);
    }
    for (final tx in expenses) {
      final method = tx.paymentMethod;
      final label = (method != null && method.contains('카드'))
          ? method
          : (method ?? '기타');
      final key = 'expense_$label';
      if (!keys.contains(key)) keys.add(key);
    }
    return keys;
  }

  // 공유 거래의 소유자 정보 (txId → {name, nickname, color})
  final Map<String, ({String name, String? nickname, String? color})>
  _sharedTxOwners = {};

  List<Widget> _buildGroupedTransactions(List<Transaction> myTransactions) {
    // 그룹 모드일 때 공유 거래를 합침
    final transactions = [...myTransactions];
    _sharedTxOwners.clear();

    if (_isGroupMode && _sharedTransactions.isNotEmpty) {
      for (final raw in _sharedTransactions) {
        final txId = raw['id'] as String;
        // 내 거래와 중복 제거
        if (myTransactions.any((t) => t.id == txId)) continue;
        try {
          // subCategory가 snake_case일 수 있으므로 fallback 처리
          final normalized = Map<String, dynamic>.from(raw);
          if (!normalized.containsKey('subCategory') &&
              normalized.containsKey('sub_category')) {
            normalized['subCategory'] = normalized['sub_category'];
          }
          final tx = Transaction.fromMap(normalized);
          transactions.add(tx);
          final owner = raw['user'] as Map<String, dynamic>? ?? {};
          _sharedTxOwners[txId] = (
            name: owner['name'] as String? ?? '',
            nickname: raw['_nickname'] as String?,
            color: raw['_color'] as String?,
          );
        } catch (_) { /* 공유 데이터 로딩 실패 시 무시 — 핵심 기능에 영향 없음 */ }
      }
    }

    if (transactions.isEmpty) return [];

    final incomes = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final showIncome = _txFilter == null || _txFilter == TransactionType.income;
    final showExpense =
        _txFilter == null || _txFilter == TransactionType.expense;

    final widgets = <Widget>[];

    // 수입: 소득 구분별
    if (showIncome && incomes.isNotEmpty) {
      final grouped = <String, List<Transaction>>{};
      for (final tx in incomes) {
        final key = tx.paymentMethod ?? '기타소득';
        grouped.putIfAbsent(key, () => []).add(tx);
      }
      for (final entry in grouped.entries) {
        final groupKey = 'income_${entry.key}';
        final groupTotal = entry.value.fold<int>(0, (sum, t) => sum + t.amount);
        widgets.add(
          _buildTxGroupCard(
            groupKey,
            entry.key,
            entry.value,
            groupTotal,
            AppColors.emerald600,
          ),
        );
      }
    }

    // 지출: 지불 방법별
    if (showExpense && expenses.isNotEmpty) {
      final grouped = <String, List<Transaction>>{};
      for (final tx in expenses) {
        final method = tx.paymentMethod;
        final label = (method != null && method.contains('카드'))
            ? method
            : (method ?? '기타');
        grouped.putIfAbsent(label, () => []).add(tx);
      }
      for (final entry in grouped.entries) {
        final groupKey = 'expense_${entry.key}';
        final groupTotal = entry.value.fold<int>(0, (sum, t) => sum + t.amount);
        widgets.add(
          _buildTxGroupCard(
            groupKey,
            entry.key,
            entry.value,
            groupTotal,
            AppColors.red600,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildTxGroupCard(
    String groupKey,
    String label,
    List<Transaction> items,
    int total,
    Color color,
  ) {
    final isExpanded = _expandedTxGroups.contains(groupKey) || _isSelectMode;
    final myCount = items
        .where((t) => !_sharedTxOwners.containsKey(t.id))
        .length;
    final sharedCount = items.length - myCount;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: AlCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // 그룹 헤더
            InkWell(
              onTap: _isSelectMode
                  ? null
                  : () => setState(() {
                      if (_expandedTxGroups.contains(groupKey)) {
                        _expandedTxGroups.remove(groupKey);
                      } else {
                        _expandedTxGroups.add(groupKey);
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
                          Text(label, style: AppTypography.label),
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
                      style: AppTypography.amountSmall.copyWith(color: color),
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
            // 펼쳐진 거래 목록
            AnimatedCrossFade(
              firstChild: SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: AppColors.gray100),
                  ...items.map((tx) => _buildInlineTransactionItem(tx)),
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

  /// 그룹 카드 안에서 표시되는 거래 항목 (라운드 없이 카드 내부 스타일)
  Widget _buildInlineTransactionItem(Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    final isShared = _sharedTxOwners.containsKey(tx.id);
    final ownerInfo = _sharedTxOwners[tx.id];
    final ownerName = ownerInfo?.nickname ?? ownerInfo?.name;
    final ownerColor = ownerInfo?.color != null
        ? Color(int.parse('FF${ownerInfo!.color!.substring(1)}', radix: 16))
        : (isShared && ownerName != null
              ? _getOwnerColor(ownerName)
              : AppColors.teal500);

    return GestureDetector(
      onTap: _isSelectMode
          ? (isShared ? null : () => _toggleSelection(tx.id))
          : (isShared ? null : () => _showEditEntrySheet(tx)),
      onLongPress: (_isSelectMode || isShared)
          ? null
          : () {
              AlConfirmDialog.show(
                context: context,
                title: '거래 삭제',
                message: "'${tx.name}' 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
                onConfirm: () async {
                  await ref
                      .read(transactionNotifierProvider(_monthKey).notifier)
                      .deleteTransaction(tx.id);
                  if (mounted) {
                    showSuccessSnackBar(context, "'${tx.name}' 항목이 삭제되었습니다");
                  }
                },
              );
            },
      child: Container(
        decoration: isShared
            ? BoxDecoration(color: ownerColor.withValues(alpha: 0.04))
            : null,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (_isSelectMode && !isShared) ...[
              Icon(
                _selectedIds.contains(tx.id)
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 20,
                color: _selectedIds.contains(tx.id)
                    ? AppColors.emerald600
                    : AppColors.gray300,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.name,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(tx.category, style: AppTypography.caption),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        tx.subCategory,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        tx.date.length >= 10
                            ? tx.date.substring(0, 10)
                            : tx.date,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.gray400,
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
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatKoreanWon(tx.amount)}',
              style: AppTypography.bodyMedium.copyWith(
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

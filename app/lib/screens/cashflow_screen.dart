import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
import '../design_system/components/al_input.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/notifiers/transaction_notifier.dart';
import '../core/providers.dart';
import '../repositories/repositories.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format_korean_won.dart';
import '../utils/snackbar_helper.dart';

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
        final notifier = ref.read(transactionNotifierProvider(_monthKey).notifier);
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

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

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
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  void _showManualEntrySheet() async {
    // 그룹 목록 가져오기
    List<Map<String, dynamic>> groups = [];
    try {
      groups = await ref.read(shareGroupServiceProvider).getMyGroups();
    } catch (_) {}

    if (!mounted) return;

    AlBottomSheet.show(
      context: context,
      title: '수기 입력',
      child: _ManualEntryForm(
        shareGroups: groups,
        onSubmit: (entry) async {
          Navigator.of(context).pop();
          final shareGroupIds = (entry['shareGroupIds'] as List<String>?) ?? [];
          await ref.read(transactionNotifierProvider(_monthKey).notifier).addTransaction(
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
    } catch (_) {}
    if (!mounted) return;

    AlBottomSheet.show(
      context: context,
      title: '거래 수정',
      child: _ManualEntryForm(
        initialData: tx.toMap(),
        shareGroups: groups,
        initialShareGroupIds: currentGroupIds,
        onSubmit: (updated) async {
          Navigator.of(context).pop();
          const allowedFields = {'type', 'name', 'amount', 'date', 'category', 'subCategory', 'paymentMethod', 'targetMonth', 'isInstallment', 'installmentMonths', 'installmentRound'};
          final payload = Map<String, dynamic>.fromEntries(
            updated.entries.where((e) => allowedFields.contains(e.key)),
          );
          await ref.read(transactionNotifierProvider(_monthKey).notifier).updateTransaction(
            tx.id,
            payload,
          );

          // 공유 그룹 변경
          final shareGroupIds = (updated['shareGroupIds'] as List<String>?) ?? [];
          if (shareGroupIds.isNotEmpty) {
            try {
              await ref.read(shareGroupServiceProvider).shareItems(
                shareGroupIds.first,
                [{'itemType': 'transaction', 'itemId': tx.id}],
              );
            } catch (_) {}
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
    } catch (_) {}
  }

  bool get _isGroupMode => _selectedGroupId != null;

  void _showGroupSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.user, color: _selectedGroupId == null ? AppColors.emerald600 : AppColors.gray500),
              title: Text('나', style: AppTypography.bodyLarge),
              trailing: _selectedGroupId == null ? Icon(LucideIcons.check, size: 18, color: AppColors.emerald600) : null,
              onTap: () {
                setState(() { _selectedGroupId = null; _selectedGroupName = '나'; _sharedTransactions = []; _lastLoadedGroupKey = null; });
                Navigator.pop(ctx);
              },
            ),
            ..._myGroups.map((g) {
              final gId = g['id'] as String;
              final gName = g['name'] as String;
              final memberCount = (g['members'] as List?)?.length ?? 0;
              final displayName = '$gName(${memberCount}명)';
              final isSelected = _selectedGroupId == gId;
              return ListTile(
                leading: Icon(LucideIcons.users, color: isSelected ? AppColors.emerald600 : AppColors.gray500),
                title: Text(displayName, style: AppTypography.bodyLarge),
                trailing: isSelected ? Icon(LucideIcons.check, size: 18, color: AppColors.emerald600) : null,
                onTap: () {
                  setState(() { _selectedGroupId = gId; _selectedGroupName = displayName; _lastLoadedGroupKey = null; });
                  Navigator.pop(ctx);
                  _loadSharedTransactions();
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
            title: '수입/지출 관리',
            subtitle: '매월 수입과 지출을 관리하세요',
            action: _myGroups.isNotEmpty ? GestureDetector(
              onTap: _showGroupSelector,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isGroupMode ? AppColors.emerald50 : AppColors.gray50,
                  borderRadius: AppRadius.fullAll,
                  border: Border.all(color: _isGroupMode ? AppColors.emerald500 : AppColors.gray200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isGroupMode ? LucideIcons.users : LucideIcons.user, size: 14,
                        color: _isGroupMode ? AppColors.emerald600 : AppColors.gray600),
                    SizedBox(width: 6),
                    Text(_selectedGroupName, style: AppTypography.bodySmall.copyWith(
                        color: _isGroupMode ? AppColors.emerald700 : AppColors.gray600)),
                    SizedBox(width: 4),
                    Icon(LucideIcons.chevronDown, size: 12, color: AppColors.gray400),
                  ],
                ),
              ),
            ) : null,
          ),

          // Month selector
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          // Scrollable content
          Expanded(
            child: _buildContent(),
          ),
        ],
        ),
    );
  }

  // 그룹에서 공유받은 거래 (비동기 로드)
  List<Map<String, dynamic>> _sharedTransactions = [];
  String? _lastLoadedGroupKey;

  Future<void> _loadSharedTransactions() async {
    final key = '${_selectedGroupId}_$_monthKey';
    if (_lastLoadedGroupKey == key) return;
    if (_selectedGroupId == null) {
      _sharedTransactions = [];
      _lastLoadedGroupKey = key;
      return;
    }
    try {
      final txs = await ref.read(shareGroupServiceProvider).getGroupTransactions(_selectedGroupId!, month: _monthKey);
      if (mounted) setState(() { _sharedTransactions = txs; _lastLoadedGroupKey = key; });
    } catch (_) {}
  }

  Widget _buildContent() {
    if (_isGroupMode) _loadSharedTransactions();

    return ref.watch(transactionNotifierProvider(_monthKey)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('데이터를 불러올 수 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500))),
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
                      SizedBox(height: AppSpacing.lg),
                      _buildMonthlySummaryCard(income: income, expense: expense, balance: balance, expenseRatio: expenseRatio, transactions: transactions),
                      SizedBox(height: AppSpacing.sectionGap),
                      _buildSmartImportCard(),
                      SizedBox(height: AppSpacing.lg),
                      AlButton(
                        label: '수기 입력',
                        onPressed: _showManualEntrySheet,
                        icon: Icon(LucideIcons.plus, size: 18, color: Colors.white),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),
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
                                    _selectedIds.length == filtered.length ? '전체 해제' : '전체 선택',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.emerald600),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                              ],
                              if (filtered.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _toggleSelectMode(allGroupKeys: _getGroupKeys(filtered)),
                                  child: Text(
                                    _isSelectMode ? '취소' : '선택',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: _isSelectMode ? AppColors.gray500 : AppColors.emerald600,
                                    ),
                                  ),
                                ),
                              if (!_isSelectMode) ...[
                                SizedBox(width: AppSpacing.md),
                                _buildTxFilterSegment(),
                              ],
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      if (filtered.isEmpty && !(_isGroupMode && _sharedTransactions.isNotEmpty))
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.inbox, size: 48, color: AppColors.gray300),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  '거래 내역이 없습니다',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  '수기 입력 또는 명세서 가져오기로 추가해 보세요',
                                  style: AppTypography.caption.copyWith(color: AppColors.gray400),
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
                            icon: Icon(LucideIcons.trash2, size: 18, color: Colors.white),
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
    final cardTxs = transactions.where(
      (t) => t.type == TransactionType.expense && t.paymentMethod != null && t.paymentMethod!.contains('카드'),
    ).toList();
    final Map<String, int> byCard = {};
    for (final tx in cardTxs) {
      byCard[tx.paymentMethod!] = (byCard[tx.paymentMethod!] ?? 0) + tx.amount;
    }
    final sortedCards = byCard.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final cardTotal = sortedCards.fold<int>(0, (sum, e) => sum + e.value);
    final hasCardData = sortedCards.isNotEmpty;

    final cardColors = [
      AppColors.blue600, AppColors.emerald500, AppColors.purple600,
      Color(0xFFF59E0B), AppColors.teal500, AppColors.red600,
    ];

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월간 요약', style: AppTypography.heading3),
          SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수입', style: AppTypography.bodySmall),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(income),
                      style: AppTypography.amountMedium.copyWith(color: AppColors.green600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지출', style: AppTypography.bodySmall),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(expense),
                      style: AppTypography.amountMedium.copyWith(color: AppColors.red600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value: expenseRatio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.green100,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.red600),
            ),
          ),
          SizedBox(height: AppSpacing.md),

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
            SizedBox(height: AppSpacing.md),
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
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      _showCardUsage ? '카드 사용 내역 접기' : '카드 사용 내역 보기',
                      style: AppTypography.caption.copyWith(color: AppColors.gray500),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      _showCardUsage ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                      size: 14, color: AppColors.gray500,
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
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(entry.key, style: AppTypography.bodySmall)),
                            Text(formatKoreanWon(entry.value), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 32,
                              child: Text('${(pct * 100).round()}%', style: AppTypography.caption.copyWith(color: AppColors.gray500), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(height: 1, color: AppColors.gray100),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('카드 합계', style: AppTypography.label.copyWith(fontSize: 12)),
                        Text(formatKoreanWon(cardTotal), style: AppTypography.label.copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _showCardUsage ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 250),
            ),
          ],
        ],
      ),
    );
  }


  void _showImportSheet() {
    String? selectedCardId;
    String? selectedFilePath;
    String? selectedFileName;
    bool isUploading = false;

    AlBottomSheet.show(
      context: context,
      title: '명세서 가져오기',
      maxHeightFraction: 0.85,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedCard = selectedCardId != null
              ? _cardCompanies.firstWhere((c) => c.id == selectedCardId)
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Step 1: 카드사 선택 ──
              Text('카드사 선택', style: AppTypography.label),
              SizedBox(height: AppSpacing.sm),
              Text(
                '업로드할 명세서의 카드사를 선택하세요',
                style: AppTypography.caption,
              ),
              SizedBox(height: AppSpacing.md),

              // 카드사 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: _cardCompanies.length,
                itemBuilder: (context, index) {
                  final card = _cardCompanies[index];
                  final isEnabled = card.enabled;
                  final isSelected = selectedCardId == card.id;

                  return Material(
                    color: isSelected
                        ? AppColors.emerald50
                        : isEnabled
                            ? Colors.white
                            : AppColors.gray50,
                    borderRadius: AppRadius.smAll,
                    child: InkWell(
                      onTap: isEnabled
                          ? () {
                              setSheetState(() => selectedCardId = card.id);
                            }
                          : null,
                      borderRadius: AppRadius.smAll,
                      splashColor: AppColors.emerald50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.emerald600
                                : AppColors.gray200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.name,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.emerald700
                                    : isEnabled
                                        ? AppColors.gray700
                                        : AppColors.gray400,
                              ),
                            ),
                            if (!isEnabled) ...[
                              SizedBox(height: 2),
                              Text(
                                '준비중',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── 선택된 카드사 정보 ──
              if (selectedCard != null) ...[
                SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 16, color: AppColors.emerald600),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        '${selectedCard.name}: ${selectedCard.format} 지원',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.emerald700,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xl),

                // ── Step 2: 파일 업로드 영역 ──
                Text('파일 업로드', style: AppTypography.label),
                SizedBox(height: AppSpacing.sm),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.gray300),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.uploadCloud,
                        size: 32,
                        color: AppColors.gray400,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '${selectedCard.format} 파일을 선택하세요',
                        style: AppTypography.bodySmall,
                      ),
                      SizedBox(height: AppSpacing.md),

                      // 파일 선택 버튼
                      if (selectedFileName != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.fileCheck, size: 14, color: AppColors.emerald600),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  selectedFileName!,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.emerald700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Material(
                        color: AppColors.emerald600,
                        borderRadius: AppRadius.smAll,
                        child: InkWell(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['xls', 'xlsx', 'csv'],
                            );
                            if (result != null && result.files.single.path != null) {
                              setSheetState(() {
                                selectedFilePath = result.files.single.path;
                                selectedFileName = result.files.single.name;
                              });
                            }
                          },
                          borderRadius: AppRadius.smAll,
                          splashColor: AppColors.emerald700,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.sm + 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.file, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  selectedFileName != null ? '다른 파일 선택' : '파일 선택',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.xl),

                // 안내 문구
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('안내', style: AppTypography.label),
                      SizedBox(height: AppSpacing.xs),
                      _buildGuideRow('카드사 홈페이지에서 이용내역을 다운로드하세요'),
                      _buildGuideRow('파일 업로드 후 내역을 미리보기로 확인할 수 있습니다'),
                      _buildGuideRow('중복 거래는 자동으로 감지됩니다'),
                    ],
                  ),
                ),

                // ── 업로드 버튼 ──
                if (selectedFilePath != null) ...[
                  SizedBox(height: AppSpacing.xl),
                  AlButton(
                    label: isUploading ? '업로드 중...' : '업로드',
                    icon: isUploading
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(LucideIcons.upload, size: 18, color: Colors.white),
                    onPressed: isUploading
                        ? () {}
                        : () async {
                            setSheetState(() => isUploading = true);
                            try {
                              final result = await ref.read(transactionServiceProvider).importTransactions(
                                    cardCompany: selectedCardId!,
                                    targetMonth: _monthKey,
                                    filePath: selectedFilePath!,
                                    fileName: selectedFileName!,
                                  );
                              final count = result['imported'] ?? 0;
                              if (mounted) {
                                Navigator.of(context).pop();
                                ref.invalidate(transactionNotifierProvider(_monthKey));
                                showSuccessSnackBar(context, '$count건의 내역을 업로드하였습니다');
                              }
                            } catch (e) {
                              setSheetState(() => isUploading = false);
                              if (mounted) showErrorSnackBar(context, '업로드 실패: $e');
                            }
                          },
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuideRow(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTypography.caption),
          Expanded(
            child: Text(text, style: AppTypography.caption),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartImportCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: AppColors.gray50,
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              LucideIcons.upload,
              size: 20,
              color: AppColors.emerald600,
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('명세서 가져오기', style: AppTypography.label),
                SizedBox(height: 2),
                Text(
                  'CSV, Excel 파일 업로드',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // 파일 선택 버튼
          Material(
            color: Colors.white,
            borderRadius: AppRadius.smAll,
            child: InkWell(
              onTap: _showImportSheet,
              borderRadius: AppRadius.smAll,
              splashColor: AppColors.emerald50,
              highlightColor: AppColors.gray100,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.gray300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.file, size: 14, color: AppColors.gray600),
                    SizedBox(width: 6),
                    Text(
                      '파일 선택',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 그룹핑된 거래를 그룹 키 목록과 함께 반환 (선택 모드에서 사용)
  List<String> _getGroupKeys(List<Transaction> transactions) {
    final keys = <String>[];
    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    for (final tx in incomes) {
      final key = 'income_${tx.paymentMethod ?? '기타소득'}';
      if (!keys.contains(key)) keys.add(key);
    }
    for (final tx in expenses) {
      final method = tx.paymentMethod;
      final label = (method != null && method.contains('카드')) ? method : (method ?? '기타');
      final key = 'expense_$label';
      if (!keys.contains(key)) keys.add(key);
    }
    return keys;
  }

  // 공유 거래의 소유자 정보 (txId → {name, nickname, color})
  final Map<String, ({String name, String? nickname, String? color})> _sharedTxOwners = {};

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
          if (!normalized.containsKey('subCategory') && normalized.containsKey('sub_category')) {
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
        } catch (_) {}
      }
    }

    if (transactions.isEmpty) return [];

    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final showIncome = _txFilter == null || _txFilter == TransactionType.income;
    final showExpense = _txFilter == null || _txFilter == TransactionType.expense;

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
        widgets.add(_buildTxGroupCard(groupKey, entry.key, entry.value, groupTotal, AppColors.emerald600));
      }
    }

    // 지출: 지불 방법별
    if (showExpense && expenses.isNotEmpty) {
      final grouped = <String, List<Transaction>>{};
      for (final tx in expenses) {
        final method = tx.paymentMethod;
        final label = (method != null && method.contains('카드')) ? method : (method ?? '기타');
        grouped.putIfAbsent(label, () => []).add(tx);
      }
      for (final entry in grouped.entries) {
        final groupKey = 'expense_${entry.key}';
        final groupTotal = entry.value.fold<int>(0, (sum, t) => sum + t.amount);
        widgets.add(_buildTxGroupCard(groupKey, entry.key, entry.value, groupTotal, AppColors.red600));
      }
    }

    return widgets;
  }

  Widget _buildTxGroupCard(String groupKey, String label, List<Transaction> items, int total, Color color) {
    final isExpanded = _expandedTxGroups.contains(groupKey) || _isSelectMode;
    final myCount = items.where((t) => !_sharedTxOwners.containsKey(t.id)).length;
    final sharedCount = items.length - myCount;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: AlCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // 그룹 헤더
            InkWell(
              onTap: _isSelectMode ? null : () => setState(() {
                if (_expandedTxGroups.contains(groupKey)) {
                  _expandedTxGroups.remove(groupKey);
                } else {
                  _expandedTxGroups.add(groupKey);
                }
              }),
              borderRadius: isExpanded
                  ? BorderRadius.only(topLeft: Radius.circular(AppRadius.lg), topRight: Radius.circular(AppRadius.lg))
                  : AppRadius.lgAll,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.smAll),
                      child: Center(child: Text('${items.length}', style: AppTypography.label.copyWith(color: color))),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTypography.label),
                        SizedBox(height: 2),
                        Row(children: [
                          Text('$myCount건', style: AppTypography.caption),
                          if (sharedCount > 0) ...[
                            SizedBox(width: AppSpacing.xs),
                            Text('· 공유 $sharedCount건', style: AppTypography.caption.copyWith(color: AppColors.teal500)),
                          ],
                        ]),
                      ],
                    )),
                    Text(formatKoreanWon(total), style: AppTypography.amountSmall.copyWith(color: color)),
                    SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(LucideIcons.chevronDown, size: 20, color: AppColors.gray400),
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
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
        : (isShared && ownerName != null ? _getOwnerColor(ownerName) : AppColors.teal500);

    return GestureDetector(
      onTap: _isSelectMode
          ? (isShared ? null : () => _toggleSelection(tx.id))
          : (isShared ? null : () => _showEditEntrySheet(tx)),
      onLongPress: (_isSelectMode || isShared) ? null : () {
        AlConfirmDialog.show(
          context: context,
          title: '거래 삭제',
          message: "'${tx.name}' 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
          onConfirm: () async {
            await ref.read(transactionNotifierProvider(_monthKey).notifier).deleteTransaction(tx.id);
            if (mounted) showSuccessSnackBar(context, "'${tx.name}' 항목이 삭제되었습니다");
          },
        );
      },
      child: Container(
        decoration: isShared ? BoxDecoration(
          color: ownerColor.withValues(alpha: 0.04),
        ) : null,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.md),
        child: Row(
          children: [
            if (_isSelectMode && !isShared) ...[
              Icon(
                _selectedIds.contains(tx.id) ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 20, color: _selectedIds.contains(tx.id) ? AppColors.emerald600 : AppColors.gray300,
              ),
              SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.name, style: AppTypography.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
                SizedBox(height: AppSpacing.xs),
                Row(children: [
                  Text(tx.category, style: AppTypography.caption),
                  SizedBox(width: AppSpacing.sm),
                  Text(tx.subCategory, style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                  SizedBox(width: AppSpacing.sm),
                  Text(tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date, style: AppTypography.caption.copyWith(color: AppColors.gray400)),
                  if (isShared && ownerName != null) ...[
                    SizedBox(width: AppSpacing.sm),
                    Flexible(child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: ownerColor.withValues(alpha: 0.1), borderRadius: AppRadius.fullAll),
                      child: Text(ownerName, style: AppTypography.caption.copyWith(color: ownerColor, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                    )),
                  ],
                ]),
              ],
            )),
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

// ---------------------------------------------------------------------------
// Manual Entry Form (used inside bottom sheet)
// ---------------------------------------------------------------------------
class _ManualEntryForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final List<Map<String, dynamic>> shareGroups;
  final List<String> initialShareGroupIds;

  const _ManualEntryForm({required this.onSubmit, this.initialData, this.shareGroups = const [], this.initialShareGroupIds = const []});

  bool get isEditMode => initialData != null;

  @override
  State<_ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<_ManualEntryForm> {
  String _type = 'income'; // income | expense
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = '급여';
  String _selectedSubCategory = '급여';
  DateTime _selectedDate = DateTime.now();

  // 수입: 소득 구분
  IncomeSource _selectedIncomeSource = IncomeSource.earned;

  // 지출: 지불 방법
  bool _isCreditCardMode = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bankTransfer;

  // 지출 > 신용카드: 카드 종류
  PaymentMethod _selectedCreditCard = PaymentMethod.shinhan;

  // 지출 > 계좌이체: 출금 계좌
  String _selectedTransferAccount = '주거래계좌';
  static const _transferAccounts = ['주거래계좌', '급여계좌', '저축계좌', '비상금계좌'];

  // 공유 그룹 선택
  final Set<String> _selectedGroupIds = {};

  // 지출 > 신용카드 > 할부
  bool _isInstallment = false;
  final _installmentMonthsController = TextEditingController();
  final _installmentRoundController = TextEditingController();

  static const _incomeCategories = ['급여'];
  static const _expenseCategories = ['생활비', '필수비', '선택비', '투자비'];

  static const _subCategoryMap = {
    '급여': ['급여', '인센티브', 'PI', '정산환급', '연차보상'],
    '생활비': ['생활', '주유'],
    '필수비': ['교육', '교통', '의료', '통신', '주거(관리비)', '세금', '경조사', '명절'],
    '선택비': ['여행', '문화'],
    '투자비': ['구독(AI)', '구독(인프라)', '대출(원금)', '대출(이자)'],
  };

  List<String> get _categories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  List<String> get _subCategories =>
      _subCategoryMap[_selectedCategory] ?? [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _type = data['type'] as String? ?? 'income';
      _nameController.text = data['name'] as String? ?? '';
      _amountController.text = (data['amount'] as int?)?.toString() ?? '';
      _selectedCategory = data['category'] as String? ?? _categories.first;
      final savedSub = data['subCategory'] as String?;
      final subOptions = _subCategoryMap[_selectedCategory] ?? [];
      _selectedSubCategory = (savedSub != null && subOptions.contains(savedSub))
          ? savedSub
          : (subOptions.isNotEmpty ? subOptions.first : '');

      final dateStr = data['date'] as String?;
      if (dateStr != null) {
        _selectedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
      }

      // 수입 관련
      _selectedIncomeSource = IncomeSource.fromString(data['incomeSource'] as String? ?? 'earned');

      // 지출 관련
      final pm = data['paymentMethod'] as String? ?? '';
      if (pm.contains('카드')) {
        _isCreditCardMode = true;
        _selectedCreditCard = PaymentMethod.fromString(pm) ?? PaymentMethod.shinhan;
      } else {
        _isCreditCardMode = false;
        _selectedPaymentMethod = PaymentMethod.fromString(pm) ?? PaymentMethod.bankTransfer;
      }
      _selectedTransferAccount = data['transferAccount'] as String? ?? _transferAccounts.first;
      _isInstallment = data['isInstallment'] == 'true';
      _installmentMonthsController.text = data['installmentMonths'] as String? ?? '';
      _installmentRoundController.text = data['installmentRound'] as String? ?? '';
    }

    // 초기 공유 그룹 선택 상태
    _selectedGroupIds.addAll(widget.initialShareGroupIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _installmentMonthsController.dispose();
    _installmentRoundController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty) {
      showErrorSnackBar(context, '항목명을 입력해 주세요');
      return;
    }
    if (amountText.isEmpty) {
      showErrorSnackBar(context, '금액을 입력해 주세요');
      return;
    }

    final amount = CurrencyInputFormatter.parse(amountText);
    if (amount == null || amount <= 0) {
      showErrorSnackBar(context, '올바른 금액을 입력해 주세요');
      return;
    }

    final entry = {
      'id': widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'type': _type,
      'name': name,
      'amount': amount,
      'date':
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      'category': _selectedCategory,
      'subCategory': _selectedSubCategory,
      'editedBy': '나',
    };

    if (_type == 'income') {
      entry['paymentMethod'] = _selectedIncomeSource.value;
    } else {
      if (_isCreditCardMode) {
        entry['paymentMethod'] = _selectedCreditCard.value;
        entry['isInstallment'] = _isInstallment;
        if (_isInstallment) {
          final months = int.tryParse(_installmentMonthsController.text.trim());
          final round = int.tryParse(_installmentRoundController.text.trim());
          if (months != null) entry['installmentMonths'] = months;
          if (round != null) entry['installmentRound'] = round;
        }
      } else {
        entry['paymentMethod'] = _selectedPaymentMethod.value;
        if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
          entry['transferAccount'] = _selectedTransferAccount;
        }
      }
    }

    if (_selectedGroupIds.isNotEmpty) {
      entry['shareGroupIds'] = _selectedGroupIds.toList();
    }

    widget.onSubmit(entry);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.emerald600),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Type toggle (income / expense)
        _buildTypeToggle(),
        SizedBox(height: AppSpacing.xl),

        // Name
        AlInput(
          label: '항목명',
          placeholder: '예: 월급, 식료품 등',
          controller: _nameController,
        ),
        SizedBox(height: AppSpacing.lg),

        // Amount
        AlInput(
          label: '금액',
          placeholder: '금액을 입력하세요',
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          prefixIcon: Icon(LucideIcons.banknote, size: 16, color: AppColors.gray500),
        ),
        SizedBox(height: AppSpacing.lg),

        // Date
        Text('날짜', style: AppTypography.label),
        SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 16, color: AppColors.gray500),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // ── 수입: 입금 계좌 ──
        if (_type == 'income') ...[
          Text('소득 구분', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          _buildEnumDropdown<IncomeSource>(
            value: _selectedIncomeSource,
            items: IncomeSource.values,
            labelOf: (e) => e.label,
            onChanged: (val) => setState(() => _selectedIncomeSource = val!),
          ),
          SizedBox(height: AppSpacing.lg),
        ],

        // ── 지출: 지불 방법 ──
        if (_type == 'expense') ...[
          Text('지불 방법', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          // 신용카드 vs 기타
          _buildEnumDropdown<PaymentMethod>(
            value: _isCreditCardMode
                ? PaymentMethod.shinhan
                : _selectedPaymentMethod,
            items: [PaymentMethod.shinhan, ...expensePaymentMethods],
            labelOf: (e) => e == PaymentMethod.shinhan ? '신용카드' : e.value,
            onChanged: (val) {
              setState(() {
                if (val == PaymentMethod.shinhan) {
                  _isCreditCardMode = true;
                  _selectedCreditCard = PaymentMethod.shinhan;
                } else {
                  _isCreditCardMode = false;
                  _selectedPaymentMethod = val!;
                }
              });
            },
          ),
          SizedBox(height: AppSpacing.lg),

          // 지출 > 신용카드 선택 시: 카드 종류 + 할부
          if (_isCreditCardMode) ...[
            Text('카드 종류', style: AppTypography.label),
            SizedBox(height: AppSpacing.sm),
            _buildEnumDropdown<PaymentMethod>(
              value: _selectedCreditCard,
              items: cardCompanies,
              labelOf: (e) => e.value,
              onChanged: (val) => setState(() => _selectedCreditCard = val!),
            ),
            SizedBox(height: AppSpacing.lg),

            // 할부 결제 섹션
            Container(
              decoration: BoxDecoration(
                color: _isInstallment ? AppColors.emerald50 : AppColors.gray50,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: _isInstallment ? AppColors.emerald200 : AppColors.gray200,
                ),
              ),
              child: Column(
                children: [
                  // 할부 토글 헤더
                  GestureDetector(
                    onTap: () => setState(() => _isInstallment = !_isInstallment),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _isInstallment
                                  ? AppColors.emerald100
                                  : AppColors.gray100,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Icon(
                              LucideIcons.creditCard,
                              size: 16,
                              color: _isInstallment
                                  ? AppColors.emerald600
                                  : AppColors.gray400,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('할부 결제', style: AppTypography.label),
                                SizedBox(height: 2),
                                Text(
                                  _isInstallment ? '할부 정보를 입력하세요' : '일시불',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          // 커스텀 토글
                          GestureDetector(
                            onTap: () => setState(() => _isInstallment = !_isInstallment),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: 44,
                              height: 24,
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _isInstallment
                                    ? AppColors.emerald600
                                    : AppColors.gray300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AnimatedAlign(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: _isInstallment
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 할부 상세 입력 (애니메이션 펼침)
                  AnimatedCrossFade(
                    duration: Duration(milliseconds: 200),
                    crossFadeState: _isInstallment
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: SizedBox.shrink(),
                    secondChild: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('할부 기간', style: AppTypography.caption.copyWith(
                                  color: AppColors.gray600,
                                )),
                                SizedBox(height: AppSpacing.xs),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadius.smAll,
                                    // border 제거 — 배경색만으로 영역 구분
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _installmentMonthsController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '12',
                                            hintStyle: AppTypography.bodyLarge.copyWith(
                                              color: AppColors.gray300,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.sm,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: AppSpacing.lg),
                                        child: Text(
                                          '개월',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('현재 회차', style: AppTypography.caption.copyWith(
                                  color: AppColors.gray600,
                                )),
                                SizedBox(height: AppSpacing.xs),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: AppRadius.smAll,
                                    // border 제거 — 배경색만으로 영역 구분
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _installmentRoundController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '3',
                                            hintStyle: AppTypography.bodyLarge.copyWith(
                                              color: AppColors.gray300,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.sm,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: AppSpacing.lg),
                                        child: Text(
                                          '회차',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],

          // 지출 > 계좌이체 선택 시: 출금 계좌
          if (!_isCreditCardMode && _selectedPaymentMethod == PaymentMethod.bankTransfer) ...[
            Text('출금 계좌', style: AppTypography.label),
            SizedBox(height: AppSpacing.sm),
            _buildDropdown(
              value: _selectedTransferAccount,
              items: _transferAccounts,
              onChanged: (val) => setState(() => _selectedTransferAccount = val!),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ],

        // ── 카테고리 (수입/지출 공통, 폼 하단) ──
        Text('카테고리', style: AppTypography.label),
        SizedBox(height: AppSpacing.sm),
        _buildDropdown(
          value: _categories.contains(_selectedCategory)
              ? _selectedCategory
              : _categories.first,
          items: _categories,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCategory = val;
                final subs = _subCategoryMap[val] ?? [];
                _selectedSubCategory = subs.isNotEmpty ? subs.first : '';
              });
            }
          },
        ),
        SizedBox(height: AppSpacing.lg),

        // 세부 카테고리
        Text('세부 카테고리', style: AppTypography.label),
        SizedBox(height: AppSpacing.sm),
        _buildDropdown(
          value: _subCategories.contains(_selectedSubCategory)
              ? _selectedSubCategory
              : (_subCategories.isNotEmpty ? _subCategories.first : ''),
          items: _subCategories,
          onChanged: (val) {
            if (val != null) setState(() => _selectedSubCategory = val);
          },
        ),
        // 공유 그룹 선택
        if (widget.shareGroups.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xl),
          Text('공유 그룹', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.shareGroups.map((g) {
              final groupId = g['id'] as String;
              final groupName = g['name'] as String;
              final isSelected = _selectedGroupIds.contains(groupId);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) { _selectedGroupIds.remove(groupId); }
                  else { _selectedGroupIds.add(groupId); }
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.emerald50 : AppColors.gray50,
                    borderRadius: AppRadius.fullAll,
                    border: Border.all(color: isSelected ? AppColors.emerald500 : AppColors.gray200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                        size: 14,
                        color: isSelected ? AppColors.emerald600 : AppColors.gray400,
                      ),
                      SizedBox(width: 6),
                      Text(groupName, style: AppTypography.bodySmall.copyWith(
                        color: isSelected ? AppColors.emerald700 : AppColors.gray600,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        SizedBox(height: AppSpacing.xl),

        // Submit
        AlButton(
          label: widget.isEditMode ? '수정' : '저장',
          onPressed: _submit,
          icon: Icon(
            widget.isEditMode ? LucideIcons.pencil : LucideIcons.check,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: AppRadius.smAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.gray500),
          style: AppTypography.bodyLarge,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEnumDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: AppRadius.smAll,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.gray500),
          style: AppTypography.bodyLarge,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(labelOf(item))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: AppRadius.smAll,
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleButton('income', '수입', LucideIcons.trendingUp),
          _toggleButton('expense', '지출', LucideIcons.trendingDown),
        ],
      ),
    );
  }

  Widget _toggleButton(String type, String label, IconData icon) {
    final isSelected = _type == type;
    final isIncome = type == 'income';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _selectedCategory = _categories.first;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: AppRadius.smAll,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isIncome ? AppColors.green600 : AppColors.red600)
                    : AppColors.gray400,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isSelected
                      ? (isIncome ? AppColors.green600 : AppColors.red600)
                      : AppColors.gray400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
import '../design_system/components/al_badge.dart';
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

  // 거래 내역 필터
  TransactionType? _txFilter;

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

  void _showManualEntrySheet() {
    AlBottomSheet.show(
      context: context,
      title: '수기 입력',
      child: _ManualEntryForm(
        onSubmit: (entry) async {
          Navigator.of(context).pop();
          await ref.read(transactionNotifierProvider(_monthKey).notifier).addTransaction(
            type: entry['type'] as String,
            name: entry['name'] as String,
            amount: entry['amount'] as int,
            date: entry['date'] as String,
            category: entry['category'] as String,
            subCategory: entry['subCategory'] as String,
          );
          if (mounted) showSuccessSnackBar(context, '거래가 추가되었습니다');
        },
      ),
    );
  }

  void _showEditEntrySheet(Transaction tx) {
    AlBottomSheet.show(
      context: context,
      title: '거래 수정',
      child: _ManualEntryForm(
        initialData: tx.toMap(),
        onSubmit: (updated) async {
          Navigator.of(context).pop();
          final payload = Map<String, dynamic>.from(updated)
            ..remove('id')
            ..remove('editedBy');
          await ref.read(transactionNotifierProvider(_monthKey).notifier).updateTransaction(
            tx.id,
            payload,
          );
          if (mounted) showSuccessSnackBar(context, '거래가 수정되었습니다');
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
          AlScreenHeader(
            title: '수입/지출 관리',
            subtitle: '매월 수입과 지출을 관리하세요',
          ),

          // Month selector
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          // Scrollable content
          Expanded(
            child: ref.watch(transactionNotifierProvider(_monthKey)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('데이터를 불러올 수 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500))),
              data: (transactions) {
                final filtered = _filterTransactions(transactions);
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
                      _buildMonthlySummaryCard(income: income, expense: expense, balance: balance, expenseRatio: expenseRatio),
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
                          _buildTxFilterSegment(),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      if (filtered.isEmpty)
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
                        ...filtered.map(_buildTransactionItem),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
          SizedBox(height: AppSpacing.lg),

          // Income vs Expense row
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
                    SizedBox(height: AppSpacing.xs),
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
          SizedBox(height: AppSpacing.lg),

          // Progress bar
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

          // Balance
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
                              final count = result['importedCount'] ?? result['count'] ?? 0;
                              if (mounted) {
                                Navigator.of(context).pop();
                                ref.invalidate(transactionNotifierProvider(_monthKey));
                                showSuccessSnackBar(context, '$count건의 거래가 가져와졌습니다');
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

  Widget _buildTransactionItem(Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    final amount = tx.amount;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        bool confirmed = false;
        await AlConfirmDialog.show(
          context: context,
          title: '거래 삭제',
          message: "'${tx.name}' 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
          onConfirm: () => confirmed = true,
        );
        return confirmed;
      },
      onDismissed: (_) async {
        await ref.read(transactionNotifierProvider(_monthKey).notifier).deleteTransaction(tx.id);
        if (mounted) showSuccessSnackBar(context, "'${tx.name}' 항목이 삭제되었습니다");
      },
      background: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.red600,
          borderRadius: AppRadius.lgAll,
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.xl),
        child: Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      child: GestureDetector(
        onTap: () => _showEditEntrySheet(tx),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          child: AlCard(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.name, style: AppTypography.bodyLarge),
                      SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          AlBadge.category(tx.category),
                          SizedBox(width: AppSpacing.sm),
                          Text(tx.subCategory, style: AppTypography.bodySmall),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(tx.date.length >= 10 ? tx.date.substring(0, 10) : tx.date, style: AppTypography.caption),
                          if (tx.editedBy != null) ...[
                            SizedBox(width: AppSpacing.sm),
                            _buildEditorBadge(tx.editedBy!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${formatKoreanWon(amount)}',
                      style: AppTypography.amountSmall.copyWith(
                        color: isIncome ? AppColors.green600 : AppColors.red600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

}

// ---------------------------------------------------------------------------
// Manual Entry Form (used inside bottom sheet)
// ---------------------------------------------------------------------------
class _ManualEntryForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;

  const _ManualEntryForm({required this.onSubmit, this.initialData});

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

  // 수입: 입금 계좌
  PaymentMethod _selectedIncomeAccount = PaymentMethod.salaryAccount;

  // 지출: 결제 수단 (카드 외)
  PaymentMethod _selectedPaymentMethod = PaymentMethod.bankTransfer;

  // 지출 > 신용카드: 카드 종류
  PaymentMethod _selectedCreditCard = PaymentMethod.shinhan;

  // 지출 > 계좌이체: 출금 계좌
  String _selectedTransferAccount = '주거래계좌';
  static const _transferAccounts = ['주거래계좌', '급여계좌', '저축계좌', '비상금계좌'];

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
      _selectedIncomeAccount = PaymentMethod.fromString(data['incomeAccount'] as String? ?? '') ?? PaymentMethod.salaryAccount;

      // 지출 관련
      _selectedPaymentMethod = PaymentMethod.fromString(data['paymentMethod'] as String? ?? '') ?? PaymentMethod.bankTransfer;
      _selectedCreditCard = PaymentMethod.fromString(data['creditCard'] as String? ?? '') ?? PaymentMethod.shinhan;
      _selectedTransferAccount = data['transferAccount'] as String? ?? _transferAccounts.first;
      _isInstallment = data['isInstallment'] == 'true';
      _installmentMonthsController.text = data['installmentMonths'] as String? ?? '';
      _installmentRoundController.text = data['installmentRound'] as String? ?? '';
    }
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
      entry['paymentMethod'] = _selectedIncomeAccount.value;
    } else {
      final isCreditCard = cardCompanies.contains(_selectedCreditCard) &&
          _selectedPaymentMethod == PaymentMethod.bankTransfer;
      if (isCreditCard) {
        entry['paymentMethod'] = _selectedCreditCard.value;
        entry['isInstallment'] = _isInstallment.toString();
        if (_isInstallment) {
          entry['installmentMonths'] = _installmentMonthsController.text.trim();
          entry['installmentRound'] = _installmentRoundController.text.trim();
        }
      } else {
        entry['paymentMethod'] = _selectedPaymentMethod.value;
        if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
          entry['transferAccount'] = _selectedTransferAccount;
        }
      }
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
          Text('입금 계좌', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          _buildEnumDropdown<PaymentMethod>(
            value: _selectedIncomeAccount,
            items: incomeAccounts,
            labelOf: (e) => e.value,
            onChanged: (val) => setState(() => _selectedIncomeAccount = val!),
          ),
          SizedBox(height: AppSpacing.lg),
        ],

        // ── 지출: 결제 수단 ──
        if (_type == 'expense') ...[
          Text('결제 수단', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          // 신용카드 vs 기타
          _buildEnumDropdown<PaymentMethod>(
            value: cardCompanies.contains(_selectedCreditCard)
                ? PaymentMethod.shinhan // 카드 선택 중임을 표시하기 위한 sentinel
                : _selectedPaymentMethod,
            items: [PaymentMethod.shinhan, ...expensePaymentMethods],
            labelOf: (e) => e == PaymentMethod.shinhan ? '신용카드' : e.value,
            onChanged: (val) {
              setState(() {
                if (val == PaymentMethod.shinhan) {
                  _selectedCreditCard = PaymentMethod.shinhan;
                } else {
                  _selectedPaymentMethod = val!;
                  _selectedCreditCard = PaymentMethod.shinhan;
                }
              });
            },
          ),
          SizedBox(height: AppSpacing.lg),

          // 지출 > 신용카드 선택 시: 카드 종류 + 할부
          if (cardCompanies.contains(_selectedCreditCard) ||
              _selectedPaymentMethod == PaymentMethod.shinhan) ...[
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
          if (_selectedPaymentMethod == PaymentMethod.bankTransfer &&
              !cardCompanies.contains(_selectedCreditCard)) ...[
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


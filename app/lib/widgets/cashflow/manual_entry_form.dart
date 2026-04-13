import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/typography.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/components/al_button.dart';
import '../../design_system/components/al_input.dart';
import '../../models/models.dart';
import '../../utils/currency_input_formatter.dart';
import '../../utils/date_format.dart';
import '../../utils/snackbar_helper.dart';

class ManualEntryForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final List<Map<String, dynamic>> shareGroups;
  final List<String> initialShareGroupIds;

  const ManualEntryForm({
    super.key,
    required this.onSubmit,
    this.initialData,
    this.shareGroups = const [],
    this.initialShareGroupIds = const [],
  });

  bool get isEditMode => initialData != null;

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
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

  List<String> get _subCategories => _subCategoryMap[_selectedCategory] ?? [];

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
      _selectedIncomeSource = IncomeSource.fromString(
        data['incomeSource'] as String? ?? 'earned',
      );

      // 지출 관련
      final pm = data['paymentMethod'] as String? ?? '';
      if (pm.contains('카드')) {
        _isCreditCardMode = true;
        _selectedCreditCard =
            PaymentMethod.fromString(pm) ?? PaymentMethod.shinhan;
      } else {
        _isCreditCardMode = false;
        _selectedPaymentMethod =
            PaymentMethod.fromString(pm) ?? PaymentMethod.bankTransfer;
      }
      _selectedTransferAccount =
          data['transferAccount'] as String? ?? _transferAccounts.first;
      _isInstallment = data['isInstallment'] == 'true';
      _installmentMonthsController.text =
          data['installmentMonths'] as String? ?? '';
      _installmentRoundController.text =
          data['installmentRound'] as String? ?? '';
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
      'id':
          widget.initialData?['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'type': _type,
      'name': name,
      'amount': amount,
      'date': toDateKey(_selectedDate),
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
        const SizedBox(height: AppSpacing.xl),

        // Name
        AlInput(
          label: '항목명',
          placeholder: '예: 월급, 식료품 등',
          controller: _nameController,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Amount
        AlInput(
          label: '금액',
          placeholder: '금액을 입력하세요',
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          prefixIcon: Icon(
            LucideIcons.banknote,
            size: 16,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date
        Text('날짜', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(width: AppSpacing.sm),
                Text(toDateKey(_selectedDate), style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 수입: 입금 계좌 ──
        if (_type == 'income') ...[
          Text('소득 구분', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _buildEnumDropdown<IncomeSource>(
            value: _selectedIncomeSource,
            items: IncomeSource.values,
            labelOf: (e) => e.label,
            onChanged: (val) => setState(() => _selectedIncomeSource = val!),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── 지출: 지불 방법 ──
        if (_type == 'expense') ...[
          Text('지불 방법', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.lg),

          // 지출 > 신용카드 선택 시: 카드 종류 + 할부
          if (_isCreditCardMode) ...[
            Text('카드 종류', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            _buildEnumDropdown<PaymentMethod>(
              value: _selectedCreditCard,
              items: cardCompanies,
              labelOf: (e) => e.value,
              onChanged: (val) => setState(() => _selectedCreditCard = val!),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 할부 결제 섹션
            _buildInstallmentSection(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 지출 > 계좌이체 선택 시: 출금 계좌
          if (!_isCreditCardMode &&
              _selectedPaymentMethod == PaymentMethod.bankTransfer) ...[
            Text('출금 계좌', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            _buildDropdown(
              value: _selectedTransferAccount,
              items: _transferAccounts,
              onChanged: (val) =>
                  setState(() => _selectedTransferAccount = val!),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],

        // ── 카테고리 (수입/지출 공통, 폼 하단) ──
        Text('카테고리', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.lg),

        // 세부 카테고리
        Text('세부 카테고리', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xl),
          Text('공유 그룹', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.shareGroups.map((g) {
              final groupId = g['id'] as String;
              final groupName = g['name'] as String;
              final isSelected = _selectedGroupIds.contains(groupId);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedGroupIds.remove(groupId);
                  } else {
                    _selectedGroupIds.add(groupId);
                  }
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.emerald50 : AppColors.gray50,
                    borderRadius: AppRadius.fullAll,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.emerald500
                          : AppColors.gray200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        size: 14,
                        color: isSelected
                            ? AppColors.emerald600
                            : AppColors.gray400,
                      ),
                      SizedBox(width: 6),
                      Text(
                        groupName,
                        style: AppTypography.bodySmall.copyWith(
                          color: isSelected
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

  Widget _buildInstallmentSection() {
    return Container(
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
                  const SizedBox(width: AppSpacing.md),
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
                  _buildToggleSwitch(),
                ],
              ),
            ),
          ),

          // 할부 상세 입력
          AnimatedCrossFade(
            duration: Duration(milliseconds: 200),
            crossFadeState: _isInstallment
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInstallmentField(
                      label: '할부 기간',
                      controller: _installmentMonthsController,
                      hint: '12',
                      suffix: '개월',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildInstallmentField(
                      label: '현재 회차',
                      controller: _installmentRoundController,
                      hint: '3',
                      suffix: '회차',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () => setState(() => _isInstallment = !_isInstallment),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _isInstallment ? AppColors.emerald600 : AppColors.gray300,
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
    );
  }

  Widget _buildInstallmentField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
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
                  suffix,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
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
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: AppColors.gray500,
          ),
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
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: AppColors.gray500,
          ),
          style: AppTypography.bodyLarge,
          items: items
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(labelOf(item))),
              )
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

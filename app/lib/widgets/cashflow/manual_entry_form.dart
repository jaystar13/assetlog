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
import '../../utils/snackbar_helper.dart';

/// 월별 (카테고리, 세부분류) 합계 입력 폼.
///
/// 같은 월·카테고리·세부분류 조합은 백엔드 upsert로 1행만 유지된다.
class ManualEntryForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final String targetMonth; // "YYYY-MM"
  final List<Map<String, dynamic>> shareGroups;
  final List<String> initialShareGroupIds;

  const ManualEntryForm({
    super.key,
    required this.onSubmit,
    required this.targetMonth,
    this.initialData,
    this.shareGroups = const [],
    this.initialShareGroupIds = const [],
  });

  bool get isEditMode => initialData != null;

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  String _type = 'expense';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _selectedCategory;
  late String _selectedSubCategory;
  final Set<String> _selectedGroupIds = {};

  List<String> get _categories =>
      _type == 'income' ? incomeCategories : expenseCategories;

  List<String> get _subCategories =>
      categorySubCategoryMap[_selectedCategory] ?? const [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _type = data['type'] as String? ?? 'expense';
      _amountController.text = (data['amount'] as int?)?.toString() ?? '';
      _noteController.text = data['note'] as String? ?? '';
      final savedCat = data['category'] as String?;
      _selectedCategory = (savedCat != null && _categories.contains(savedCat))
          ? savedCat
          : _categories.first;
      final savedSub = data['subCategory'] as String?;
      final subOptions = categorySubCategoryMap[_selectedCategory] ?? const [];
      _selectedSubCategory =
          (savedSub != null && subOptions.contains(savedSub))
              ? savedSub
              : (subOptions.isNotEmpty ? subOptions.first : '');
    } else {
      _selectedCategory = _categories.first;
      final subs = categorySubCategoryMap[_selectedCategory] ?? const [];
      _selectedSubCategory = subs.isNotEmpty ? subs.first : '';
    }
    _selectedGroupIds.addAll(widget.initialShareGroupIds);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      showErrorSnackBar(context, '금액을 입력해 주세요');
      return;
    }
    final amount = CurrencyInputFormatter.parse(amountText);
    if (amount == null || amount <= 0) {
      showErrorSnackBar(context, '올바른 금액을 입력해 주세요');
      return;
    }
    if (_selectedSubCategory.isEmpty) {
      showErrorSnackBar(context, '세부 카테고리를 선택해 주세요');
      return;
    }

    final entry = <String, dynamic>{
      'id': widget.initialData?['id'],
      'type': _type,
      'targetMonth': widget.targetMonth,
      'category': _selectedCategory,
      'subCategory': _selectedSubCategory,
      'amount': amount,
      'note': _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    };

    if (_selectedGroupIds.isNotEmpty) {
      entry['shareGroupIds'] = _selectedGroupIds.toList();
    }

    widget.onSubmit(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Type toggle
        _buildTypeToggle(),
        const SizedBox(height: AppSpacing.xl),

        // Category
        Text('카테고리', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        _buildDropdown(
          value: _categories.contains(_selectedCategory)
              ? _selectedCategory
              : _categories.first,
          items: _categories,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedCategory = val;
              final subs = categorySubCategoryMap[val] ?? const [];
              _selectedSubCategory = subs.isNotEmpty ? subs.first : '';
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Sub Category
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

        // Note (비고)
        AlInput(
          label: '비고 (선택)',
          placeholder: '특이사항을 적어주세요',
          controller: _noteController,
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
          value: items.contains(value) ? value : null,
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
          if (_type == type) return;
          setState(() {
            _type = type;
            _selectedCategory = _categories.first;
            final subs = categorySubCategoryMap[_selectedCategory] ?? const [];
            _selectedSubCategory = subs.isNotEmpty ? subs.first : '';
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

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
import '../../utils/format_korean_won.dart';
import '../../utils/snackbar_helper.dart';

/// 새 자산 추가 폼 (Bottom Sheet 내부)
class AddAssetForm extends StatefulWidget {
  final List<AssetGroup> assetGroups;
  final List<Map<String, dynamic>> shareGroups;
  final Future<void> Function({
    required String categoryId,
    required String name,
    required int value,
    List<String>? shareGroupIds,
  }) onSubmit;

  const AddAssetForm({
    super.key,
    required this.assetGroups,
    required this.shareGroups,
    required this.onSubmit,
  });

  @override
  State<AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<AddAssetForm> {
  late String _selectedGroup;
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _selectedShareGroupIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.assetGroups.isNotEmpty
        ? widget.assetGroups.first.id
        : 'cash';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              value: _selectedGroup,
              isExpanded: true,
              icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.gray500),
              style: AppTypography.bodyLarge,
              items: widget.assetGroups
                  .map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Row(
                          children: [
                            Icon(g.icon, size: 18, color: g.colors.text),
                            const SizedBox(width: AppSpacing.sm),
                            Text(g.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGroup = val);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        AlInput(
          label: '자산명',
          placeholder: '예: 서울 아파트, S&P 500 ETF 등',
          controller: _nameController,
        ),
        const SizedBox(height: AppSpacing.lg),

        AlInput(
          label: '현재 가치 (원)',
          placeholder: '금액을 입력하세요',
          controller: _valueController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          prefixIcon: Icon(LucideIcons.banknote, size: 16, color: AppColors.gray500),
        ),

        // 공유 그룹 선택
        if (widget.shareGroups.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('공유 그룹', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _buildShareGroupChips(),
        ],
        const SizedBox(height: AppSpacing.xl),

        AlButton(
          label: '자산 추가',
          icon: Icon(LucideIcons.plus, size: 18, color: Colors.white),
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildShareGroupChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: widget.shareGroups.map((g) {
        final gId = g['id'] as String;
        final gName = g['name'] as String;
        final sel = _selectedShareGroupIds.contains(gId);
        return GestureDetector(
          onTap: () => setState(() {
            sel ? _selectedShareGroupIds.remove(gId) : _selectedShareGroupIds.add(gId);
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? AppColors.emerald50 : AppColors.gray50,
              borderRadius: AppRadius.fullAll,
              border: Border.all(color: sel ? AppColors.emerald500 : AppColors.gray200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sel ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 14,
                  color: sel ? AppColors.emerald600 : AppColors.gray400,
                ),
                SizedBox(width: 6),
                Text(
                  gName,
                  style: AppTypography.bodySmall.copyWith(
                    color: sel ? AppColors.emerald700 : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final valueText = _valueController.text.trim();

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

    final isDebt = _selectedGroup == 'loans';
    final actualValue = isDebt ? -value.abs() : value;

    Navigator.of(context).pop();

    await widget.onSubmit(
      categoryId: _selectedGroup,
      name: name,
      value: actualValue,
      shareGroupIds: _selectedShareGroupIds.isNotEmpty
          ? _selectedShareGroupIds.toList()
          : null,
    );
  }
}

/// 자산 수정 폼 (Bottom Sheet 내부)
class EditAssetForm extends StatefulWidget {
  final AssetItem item;
  final AssetGroup group;
  final Future<void> Function({
    required String assetId,
    required String name,
    required int value,
  }) onSubmit;

  const EditAssetForm({
    super.key,
    required this.item,
    required this.group,
    required this.onSubmit,
  });

  @override
  State<EditAssetForm> createState() => _EditAssetFormState();
}

class _EditAssetFormState extends State<EditAssetForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _valueController = TextEditingController(
      text: widget.item.currentValue.abs().toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            color: widget.group.colors.light,
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            children: [
              Icon(widget.group.icon, size: 18, color: widget.group.colors.text),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.group.name,
                style: AppTypography.label.copyWith(color: widget.group.colors.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        AlInput(label: '자산명', placeholder: '예: 서울 아파트', controller: _nameController),
        const SizedBox(height: AppSpacing.lg),

        AlInput(
          label: '현재 가치 (원)',
          placeholder: '금액을 입력하세요',
          controller: _valueController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          prefixIcon: Icon(LucideIcons.banknote, size: 16, color: AppColors.gray500),
        ),
        const SizedBox(height: AppSpacing.xl),

        AlButton(
          label: '수정',
          icon: Icon(LucideIcons.pencil, size: 18, color: Colors.white),
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final valueText = _valueController.text.trim();

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

    final isDebt = widget.group.id == 'loans';
    final actualValue = isDebt ? -value.abs().toInt() : value.toInt();

    Navigator.of(context).pop();

    await widget.onSubmit(
      assetId: widget.item.id,
      name: name,
      value: actualValue,
    );
  }
}

/// 자산 일괄 업데이트 폼 (Bottom Sheet 내부)
class UpdateAssetsForm extends StatefulWidget {
  final AssetGroup group;
  final Future<void> Function(Map<String, int> updates) onSubmit;

  const UpdateAssetsForm({
    super.key,
    required this.group,
    required this.onSubmit,
  });

  @override
  State<UpdateAssetsForm> createState() => _UpdateAssetsFormState();
}

class _UpdateAssetsFormState extends State<UpdateAssetsForm> {
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final item in widget.group.items) {
      _controllers[item.id] = TextEditingController(
        text: item.currentValue.abs().toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.group.items.map((item) {
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
                  controller: _controllers[item.id],
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
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    Navigator.of(context).pop();

    final isDebt = widget.group.id == 'loans';
    final updates = <String, int>{};

    for (final item in widget.group.items) {
      final text = _controllers[item.id]?.text ?? '';
      final value = CurrencyInputFormatter.parse(text);
      if (value != null) {
        updates[item.id] = isDebt ? -value.abs() : value;
      }
    }

    await widget.onSubmit(updates);
  }
}

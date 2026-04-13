import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/typography.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/components/al_button.dart';
import '../../models/models.dart';
import '../../utils/snackbar_helper.dart';

/// 명세서 가져오기 Bottom Sheet 내부 콘텐츠.
///
/// 카드사 선택 → 파일 업로드 → 업로드 실행 흐름을 제공합니다.
class ImportSheetContent extends StatefulWidget {
  final List<CardCompany> cardCompanies;
  final Future<Map<String, dynamic>> Function({
    required String cardCompany,
    required String targetMonth,
    required String filePath,
    required String fileName,
  }) onImport;
  final String targetMonth;
  final VoidCallback? onSuccess;

  const ImportSheetContent({
    super.key,
    required this.cardCompanies,
    required this.onImport,
    required this.targetMonth,
    this.onSuccess,
  });

  @override
  State<ImportSheetContent> createState() => _ImportSheetContentState();
}

class _ImportSheetContentState extends State<ImportSheetContent> {
  String? _selectedCardId;
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;

  CardCompany? get _selectedCard => _selectedCardId != null
      ? widget.cardCompanies.firstWhere((c) => c.id == _selectedCardId)
      : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Step 1: 카드사 선택 ──
        Text('카드사 선택', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        Text('업로드할 명세서의 카드사를 선택하세요', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.md),

        _buildCardGrid(),

        // ── 선택된 카드사 정보 ──
        if (_selectedCard != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSelectedCardInfo(_selectedCard!),
          const SizedBox(height: AppSpacing.xl),

          // ── Step 2: 파일 업로드 영역 ──
          Text('파일 업로드', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          _buildFileUploadArea(_selectedCard!),

          const SizedBox(height: AppSpacing.xl),
          _buildGuideSection(),

          // ── 업로드 버튼 ──
          if (_selectedFilePath != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildUploadButton(),
          ],
        ],
      ],
    );
  }

  Widget _buildCardGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: widget.cardCompanies.length,
      itemBuilder: (context, index) {
        final card = widget.cardCompanies[index];
        final isEnabled = card.enabled;
        final isSelected = _selectedCardId == card.id;

        return Material(
          color: isSelected
              ? AppColors.emerald50
              : isEnabled
              ? Colors.white
              : AppColors.gray50,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            onTap: isEnabled
                ? () => setState(() => _selectedCardId = card.id)
                : null,
            borderRadius: AppRadius.smAll,
            splashColor: AppColors.emerald50,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: isSelected ? AppColors.emerald600 : AppColors.gray200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.name,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    );
  }

  Widget _buildSelectedCardInfo(CardCompany card) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 16, color: AppColors.emerald600),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${card.name}: ${card.format} 지원',
            style: AppTypography.bodySmall.copyWith(color: AppColors.emerald700),
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadArea(CardCompany card) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.gray300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Icon(LucideIcons.uploadCloud, size: 32, color: AppColors.gray400),
          const SizedBox(height: AppSpacing.sm),
          Text('${card.format} 파일을 선택하세요', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),

          if (_selectedFileName != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileCheck, size: 14, color: AppColors.emerald600),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _selectedFileName!,
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
              onTap: _pickFile,
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
                      _selectedFileName != null ? '다른 파일 선택' : '파일 선택',
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
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx', 'csv'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Widget _buildGuideSection() {
    return Container(
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
          const SizedBox(height: AppSpacing.xs),
          _buildGuideRow('카드사 홈페이지에서 이용내역을 다운로드하세요'),
          _buildGuideRow('파일 업로드 후 내역을 미리보기로 확인할 수 있습니다'),
          _buildGuideRow('중복 거래는 자동으로 감지됩니다'),
        ],
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
          Expanded(child: Text(text, style: AppTypography.caption)),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return AlButton(
      label: _isUploading ? '업로드 중...' : '업로드',
      icon: _isUploading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(LucideIcons.upload, size: 18, color: Colors.white),
      onPressed: _isUploading
          ? () {}
          : () async {
              setState(() => _isUploading = true);
              try {
                final result = await widget.onImport(
                  cardCompany: _selectedCardId!,
                  targetMonth: widget.targetMonth,
                  filePath: _selectedFilePath!,
                  fileName: _selectedFileName!,
                );
                final count = result['imported'] ?? 0;
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showSuccessSnackBar(context, '$count건의 내역을 업로드하였습니다');
                  widget.onSuccess?.call();
                }
              } catch (e) {
                if (!context.mounted) return;
                setState(() => _isUploading = false);
                showErrorSnackBar(context, '업로드 실패: $e');
              }
            },
    );
  }
}

/// 명세서 가져오기 진입 카드 (메인 화면에 표시)
class SmartImportCard extends StatelessWidget {
  final VoidCallback onTap;

  const SmartImportCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(LucideIcons.upload, size: 20, color: AppColors.emerald600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('명세서 가져오기', style: AppTypography.label),
                SizedBox(height: 2),
                Text('CSV, Excel 파일 업로드', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Material(
            color: Colors.white,
            borderRadius: AppRadius.smAll,
            child: InkWell(
              onTap: onTap,
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
}

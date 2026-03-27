import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/radius.dart';

/// 공통 확인 다이얼로그 컴포넌트
///
/// 삭제 등 되돌릴 수 없는 작업에 대한 확인을 받을 때 사용합니다.
/// [AlConfirmDialog.show]로 간편하게 호출할 수 있습니다.
class AlConfirmDialog {
  /// 확인 다이얼로그를 표시하고, 사용자가 확인 버튼을 누르면 [onConfirm]을 실행합니다.
  ///
  /// - [title]: 다이얼로그 제목 (예: '거래 삭제', '자산 삭제')
  /// - [message]: 본문 메시지 (예: "'월급' 항목을 삭제하시겠습니까?")
  /// - [confirmLabel]: 확인 버튼 텍스트 (기본: '삭제')
  /// - [cancelLabel]: 취소 버튼 텍스트 (기본: '취소')
  /// - [isDestructive]: true면 확인 버튼이 빨간색 (기본: true)
  /// - [onConfirm]: 확인 버튼 콜백
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = '삭제',
    String cancelLabel = '취소',
    bool isDestructive = true,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text(title, style: AppTypography.heading3),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              cancelLabel,
              style: TextStyle(color: AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? AppColors.red600 : AppColors.emerald600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

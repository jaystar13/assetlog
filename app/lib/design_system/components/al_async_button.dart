import 'package:flutter/material.dart';
import 'al_button.dart';
import '../../utils/snackbar_helper.dart';

/// 비동기 작업 실행 중 로딩 상태를 자동 관리하는 버튼.
///
/// [onPressed]가 완료될 때까지 버튼이 비활성화되며 [savingLabel]을 표시합니다.
/// 에러 발생 시 스낵바로 알림합니다.
class AlAsyncButton extends StatefulWidget {
  final String label;
  final String savingLabel;
  final Future<void> Function() onPressed;
  final AlButtonVariant variant;
  final Widget? icon;

  const AlAsyncButton({
    super.key,
    required this.label,
    this.savingLabel = '저장 중...',
    required this.onPressed,
    this.variant = AlButtonVariant.primary,
    this.icon,
  });

  @override
  State<AlAsyncButton> createState() => _AlAsyncButtonState();
}

class _AlAsyncButtonState extends State<AlAsyncButton> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlButton(
      label: _isSaving ? widget.savingLabel : widget.label,
      variant: widget.variant,
      icon: widget.icon,
      onPressed: _isSaving
          ? null
          : () async {
              setState(() => _isSaving = true);
              try {
                await widget.onPressed();
              } catch (e) {
                if (context.mounted) showErrorSnackBar(context, '실패: $e');
              } finally {
                if (context.mounted) setState(() => _isSaving = false);
              }
            },
    );
  }
}

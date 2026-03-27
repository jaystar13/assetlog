import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/radius.dart';

enum AlButtonVariant { primary, secondary, text, danger }

class AlButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AlButtonVariant variant;
  final Widget? icon;
  final bool fullWidth;

  const AlButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AlButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case AlButtonVariant.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald600,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            elevation: 2,
          ),
          child: _content(Colors.white),
        );
      case AlButtonVariant.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gray700,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            side: BorderSide(color: AppColors.gray300),
          ),
          child: _content(AppColors.gray700),
        );
      case AlButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.emerald600,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: _content(AppColors.emerald600),
        );
      case AlButtonVariant.danger:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.red600,
            padding: EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          ),
          child: _content(AppColors.red600),
        );
    }
  }

  Widget _content(Color textColor) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          SizedBox(width: 8),
          Text(label, style: AppTypography.button.copyWith(color: textColor)),
        ],
      );
    }
    return Text(label, style: AppTypography.button.copyWith(color: textColor));
  }
}

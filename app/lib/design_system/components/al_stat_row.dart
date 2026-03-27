import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radius.dart';

class AlStatRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? backgroundColor;

  const AlStatRow({
    super.key,
    required this.dotColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.bodyMedium),
            ],
          ),
          Text(
            value,
            style: AppTypography.amountSmall.copyWith(
              color: valueColor ?? AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

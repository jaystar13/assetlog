import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

class AlBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const AlBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory AlBadge.category(String category) {
    final colors = _categoryColors[category] ??
        (bg: AppColors.gray100, text: AppColors.gray700);
    return AlBadge(
      label: category,
      backgroundColor: colors.bg,
      textColor: colors.text,
    );
  }

  static final Map<String, ({Color bg, Color text})> _categoryColors = {
    'Essential': (bg: AppColors.red100, text: AppColors.red700),
    'Living': (bg: AppColors.orange100, text: AppColors.orange700),
    'Optional': (bg: AppColors.purple100, text: AppColors.purple600),
    'Salary': (bg: AppColors.green100, text: AppColors.green600),
    'Financial': (bg: AppColors.green100, text: AppColors.green600),
    'Business': (bg: AppColors.green100, text: AppColors.green600),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

class AlMonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const AlMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  String get _label =>
      '${selectedMonth.year}년 ${selectedMonth.month}월';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(onPrevious, LucideIcons.chevronLeft),
          Text(_label, style: AppTypography.heading3),
          _navButton(onNext, LucideIcons.chevronRight),
        ],
      ),
    );
  }

  Widget _navButton(VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: AppColors.gray600),
      ),
    );
  }
}

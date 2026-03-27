import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../tokens/colors.dart';

class AlChangeIndicator extends StatelessWidget {
  final String value;
  final bool isPositive;
  final double iconSize;
  final double fontSize;

  const AlChangeIndicator({
    super.key,
    required this.value,
    required this.isPositive,
    this.iconSize = 16,
    this.fontSize = 14,
  });

  factory AlChangeIndicator.percent({
    required double percent,
    double iconSize = 16,
    double fontSize = 14,
  }) {
    return AlChangeIndicator(
      value: '${percent.abs().toStringAsFixed(1)}%',
      isPositive: percent >= 0,
      iconSize: iconSize,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.emerald600 : AppColors.red600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown,
          size: iconSize,
          color: color,
        ),
        SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

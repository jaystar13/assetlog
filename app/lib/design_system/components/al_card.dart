import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radius.dart';

enum AlCardVariant { elevated, flat }

class AlCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AlCardVariant variant;
  final Color? color;
  final Gradient? gradient;

  const AlCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AlCardVariant.elevated,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: AppRadius.lgAll,
        boxShadow: variant == AlCardVariant.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

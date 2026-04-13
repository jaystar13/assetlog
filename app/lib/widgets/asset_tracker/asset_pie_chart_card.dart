import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/typography.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/components/al_card.dart';
import '../../models/models.dart';
import '../../utils/format_korean_won.dart';

/// 자산 구성 파이 차트 카드
class AssetPieChartCard extends StatelessWidget {
  final List<AssetGroup> groups;

  const AssetPieChartCard({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    final positiveGroups = groups.where((g) => g.totalValue > 0).toList();
    final totalPositive = positiveGroups.fold<num>(0, (sum, g) => sum + g.totalValue);

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('자산 구성', style: AppTypography.heading3),
              Row(
                children: [
                  Text(
                    '총 ${formatKoreanWon(groups.fold<num>(0, (sum, g) => sum + g.totalValue))}',
                    style: AppTypography.label,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: positiveGroups.map((group) {
                        return PieChartSectionData(
                          value: group.totalValue.toDouble(),
                          color: group.colors.bg,
                          radius: 32,
                          title: '',
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: positiveGroups.map((group) {
                    final percent = totalPositive > 0
                        ? (group.totalValue / totalPositive * 100)
                        : 0.0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: group.colors.bg,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            group.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.gray700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

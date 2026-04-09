import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_section_header.dart';
import '../design_system/components/al_screen_header.dart';
import '../models/models.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  PeriodFilter _selectedPeriod = PeriodFilter.threeMonths;

  /// 선택된 기간의 월 키 목록 (YYYY-MM)
  List<String> get _periodMonthKeys {
    final now = DateTime.now();
    final count = _selectedPeriod == PeriodFilter.threeMonths ? 3 : 6;
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - (count - 1 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '리포트',
            subtitle: '자산 현황을 한 눈에 확인하세요',
            action: _buildPeriodFilter(),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                top: AppSpacing.lg,
                bottom: AppSpacing.bottomNavSafeArea,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net worth trend
                  _buildNetWorthTrendCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Income vs expense
                  _buildIncomeExpenseCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Asset category stacked bar
                  _buildAssetCategoryCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Monthly detail table
                  _buildMonthlyDetailTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Period filter (sticky header)
  // -----------------------------------------------------------------------

  Widget _buildPeriodFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _periodButton(PeriodFilter.threeMonths),
        SizedBox(width: AppSpacing.sm),
        _periodButton(PeriodFilter.sixMonths),
      ],
    );
  }

  Widget _periodButton(PeriodFilter filter) {
    final isSelected = _selectedPeriod == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = filter),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald600 : Colors.transparent,
          borderRadius: AppRadius.fullAll,
          border: Border.all(
            color: isSelected ? AppColors.emerald600 : AppColors.gray300,
          ),
        ),
        child: Text(
          filter.label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.gray600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Chart helpers
  // -----------------------------------------------------------------------

  Widget _chartCard({
    required String title,
    required Widget chart,
    Widget? legend,
  }) {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(title: title),
          if (legend != null) ...[
            SizedBox(height: AppSpacing.sm),
            legend,
          ],
          SizedBox(height: AppSpacing.lg),
          SizedBox(height: 256, child: chart),
        ],
      ),
    );
  }

  FlGridData get _defaultGrid => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.gray200,
          strokeWidth: 0.5,
        ),
      );

  FlBorderData get _noBorder => FlBorderData(show: false);

  // -----------------------------------------------------------------------
  // 1) Net Worth Trend - Area Chart (emerald)
  // -----------------------------------------------------------------------

  Widget _buildNetWorthTrendCard() {
    final months = _periodMonthKeys;
    final assetService = ref.watch(assetServiceProvider);

    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      key: ValueKey('networth_${_selectedPeriod.value}'),
      future: Future.wait(months.map((m) => assetService.getAssets(month: m))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(
            title: '순자산 추이',
            chart: Center(child: CircularProgressIndicator()),
          );
        }

        final allMonthsAssets = snapshot.data!;
        final netWorths = <double>[];

        for (final assets in allMonthsAssets) {
          num total = 0;
          for (final asset in assets) {
            final history = asset['valueHistory'] as List<dynamic>? ?? [];
            if (history.isEmpty) continue;
            final value = (history.first['value'] as num);
            final categoryId = asset['categoryId'] as String;
            if (categoryId == 'loans') {
              total -= value.abs();
            } else {
              total += value;
            }
          }
          netWorths.add(total.toDouble());
        }

        if (netWorths.every((v) => v == 0)) {
          return _chartCard(
            title: '순자산 추이',
            chart: Center(child: Text('데이터가 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500))),
          );
        }

        final spots = netWorths.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
        final minVal = netWorths.reduce((a, b) => a < b ? a : b);
        final maxVal = netWorths.reduce((a, b) => a > b ? a : b);
        final padding = maxVal == minVal ? maxVal.abs() * 0.1 + 1 : (maxVal - minVal) * 0.15;
        final minY = minVal - padding;
        final maxY = maxVal + padding;

        return _chartCard(
          title: '순자산 추이',
          chart: LineChart(
            LineChartData(
              minX: 0,
              maxX: (months.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              clipData: FlClipData.all(),
              gridData: _defaultGrid,
              borderData: _noBorder,
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (value != idx.toDouble() || idx < 0 || idx >= months.length) return SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(formatMonth(months[idx]), style: AppTypography.caption),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    getTitlesWidget: (value, meta) => Text(formatChartWon(value), style: AppTypography.caption),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.gray800,
                  getTooltipItems: (spots) => spots.map((s) {
                    return LineTooltipItem(
                      formatChartWon(s.y),
                      TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.emerald500,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.emerald500.withValues(alpha: 0.3),
                        AppColors.emerald500.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // 2) Income vs Expense - Grouped Bar Chart (emerald + red)
  // -----------------------------------------------------------------------

  // 카테고리별 색상
  static const _expenseCategoryColors = {
    '생활비': Color(0xFFF59E0B),
    '필수비': AppColors.blue600,
    '선택비': AppColors.purple600,
    '투자비': AppColors.teal500,
  };

  Widget _buildIncomeExpenseCard() {
    final months = _periodMonthKeys;
    final txService = ref.watch(transactionServiceProvider);

    return FutureBuilder<List<List<Transaction>>>(
      key: ValueKey('incomeexpense_${_selectedPeriod.value}'),
      future: Future.wait(months.map((m) => txService.getTransactions(month: m))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(
            title: '수입 vs 지출',
            chart: Center(child: CircularProgressIndicator()),
          );
        }

        final allMonthsTx = snapshot.data!;
        final categoryOrder = ['생활비', '필수비', '선택비', '투자비'];

        final groups = <BarChartGroupData>[];
        for (int i = 0; i < months.length; i++) {
          final txs = allMonthsTx[i];
          final income = txs
              .where((t) => t.type == TransactionType.income)
              .fold<double>(0, (sum, t) => sum + t.amount);

          // 지출 카테고리별
          final Map<String, double> byCat = {};
          for (final tx in txs.where((t) => t.type == TransactionType.expense)) {
            byCat[tx.category] = (byCat[tx.category] ?? 0) + tx.amount;
          }

          double stackFrom = 0;
          final stacks = <BarChartRodStackItem>[];
          for (final cat in categoryOrder) {
            final val = byCat[cat] ?? 0;
            if (val > 0) {
              stacks.add(BarChartRodStackItem(
                stackFrom, stackFrom + val,
                _expenseCategoryColors[cat] ?? AppColors.gray400,
              ));
              stackFrom += val;
            }
          }

          groups.add(BarChartGroupData(
            x: i,
            barsSpace: 2,
            barRods: [
              BarChartRodData(
                toY: income,
                color: AppColors.emerald500,
                width: 10,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: stackFrom,
                rodStackItems: stacks,
                color: stacks.isEmpty ? AppColors.gray200 : null,
                width: 10,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
              ),
            ],
          ));
        }

        return _chartCard(
          title: '수입 vs 지출',
          legend: _buildLegend([
            _LegendItem('수입', AppColors.emerald500),
            ...categoryOrder.map((c) => _LegendItem(c, _expenseCategoryColors[c] ?? AppColors.gray400)),
          ]),
          chart: BarChart(
            BarChartData(
              barGroups: groups,
              gridData: _defaultGrid,
              borderData: _noBorder,
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) return SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(formatMonth(months[idx]), style: AppTypography.caption),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) => Text(formatChartWon(value), style: AppTypography.caption),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.gray800,
                  getTooltipItem: (group, groupIdx, rod, rodIdx) {
                    final label = rodIdx == 0 ? '수입' : '지출';
                    return BarTooltipItem(
                      '$label ${formatChartWon(rod.toY)}',
                      TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Asset Category - Stacked Bar Chart
  // -----------------------------------------------------------------------

  static const _assetCategoryColors = {
    'real-estate': AppColors.blue600,
    'stocks': AppColors.green500,
    'cash': AppColors.purple600,
    'loans': AppColors.red600,
  };
  static const _assetCategoryLabels = {
    'real-estate': '부동산',
    'stocks': '주식',
    'cash': '현금',
    'loans': '부채',
  };

  Widget _buildAssetCategoryCard() {
    final months = _periodMonthKeys;
    final assetService = ref.watch(assetServiceProvider);

    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      key: ValueKey('assetcat_${_selectedPeriod.value}'),
      future: Future.wait(months.map((m) => assetService.getAssets(month: m))),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(title: '월별 자산 추이', chart: Center(child: CircularProgressIndicator()));
        }

        final categories = ['real-estate', 'stocks', 'cash', 'loans'];
        final allMonths = snapshot.data!;

        final groups = <BarChartGroupData>[];
        for (int i = 0; i < months.length; i++) {
          final assets = allMonths[i];
          final Map<String, double> byCat = {};
          for (final asset in assets) {
            final catId = asset['categoryId'] as String;
            final history = asset['valueHistory'] as List<dynamic>? ?? [];
            final value = history.isNotEmpty ? (history.first['value'] as num).toDouble().abs() : 0.0;
            byCat[catId] = (byCat[catId] ?? 0) + value;
          }

          // 자산 스택 (부동산 + 주식 + 현금)
          double stackFrom = 0;
          final stacks = <BarChartRodStackItem>[];
          for (final cat in ['real-estate', 'stocks', 'cash']) {
            final val = byCat[cat] ?? 0;
            if (val > 0) {
              stacks.add(BarChartRodStackItem(stackFrom, stackFrom + val, _assetCategoryColors[cat]!));
              stackFrom += val;
            }
          }
          final debtVal = byCat['loans'] ?? 0;

          groups.add(BarChartGroupData(
            x: i,
            barsSpace: 2,
            barRods: [
              BarChartRodData(
                toY: stackFrom,
                rodStackItems: stacks,
                color: stacks.isEmpty ? AppColors.gray200 : null,
                width: 14,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
              ),
              BarChartRodData(
                toY: debtVal,
                color: AppColors.red600,
                width: 14,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
              ),
            ],
          ));
        }

        return _chartCard(
          title: '월별 자산 추이',
          legend: _buildLegend(categories.map((c) => _LegendItem(_assetCategoryLabels[c]!, _assetCategoryColors[c]!)).toList()),
          chart: BarChart(
            BarChartData(
              barGroups: groups,
              gridData: _defaultGrid,
              borderData: _noBorder,
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, interval: 1, reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (value != idx.toDouble() || idx < 0 || idx >= months.length) return SizedBox.shrink();
                      return Padding(padding: EdgeInsets.only(top: AppSpacing.sm), child: Text(formatMonth(months[idx]), style: AppTypography.caption));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 52, getTitlesWidget: (value, meta) => Text(formatChartWon(value), style: AppTypography.caption)),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.gray800,
                  getTooltipItem: (group, groupIdx, rod, rodIdx) {
                    final label = rodIdx == 0 ? '자산' : '부채';
                    return BarTooltipItem('$label ${formatChartWon(rod.toY)}', TextStyle(color: Colors.white, fontSize: 12));
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // 6) Monthly detail table
  // -----------------------------------------------------------------------

  Widget _buildMonthlyDetailTable() {
    final months = _periodMonthKeys;
    final assetService = ref.watch(assetServiceProvider);
    final txService = ref.watch(transactionServiceProvider);

    return FutureBuilder<List<List<dynamic>>>(
      key: ValueKey('detail_${_selectedPeriod.value}'),
      future: Future.wait([
        Future.wait(months.map((m) => assetService.getAssets(month: m))),
        Future.wait(months.map((m) => txService.getTransactions(month: m))),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlSectionHeader(title: '월별 상세 내역'),
                SizedBox(height: AppSpacing.xl),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        }

        final allAssets = (snapshot.data![0] as List).map((e) => (e as List).cast<Map<String, dynamic>>()).toList();
        final allTxs = (snapshot.data![1] as List).cast<List<Transaction>>();

        return AlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlSectionHeader(title: '월별 상세 내역'),
              SizedBox(height: AppSpacing.lg),
              _tableRow(month: '월', income: '수입', expense: '지출', netWorth: '순자산', isHeader: true),
              Divider(color: AppColors.gray200, height: 1),
              ...months.asMap().entries.map((e) {
                final i = e.key;
                final month = e.value;

                // 순자산
                num netWorth = 0;
                for (final asset in allAssets[i]) {
                  final history = asset['valueHistory'] as List<dynamic>? ?? [];
                  if (history.isEmpty) continue;
                  final value = (history.first['value'] as num);
                  final catId = asset['categoryId'] as String;
                  if (catId == 'loans') { netWorth -= value.abs(); } else { netWorth += value; }
                }

                // 수입/지출
                int income = 0, expense = 0;
                for (final tx in allTxs[i]) {
                  if (tx.type == TransactionType.income) { income += tx.amount; } else { expense += tx.amount; }
                }

                return Column(
                  children: [
                    _tableRow(
                      month: formatMonth(month),
                      income: formatChartWon(income),
                      expense: formatChartWon(expense),
                      netWorth: formatChartWon(netWorth),
                    ),
                    Divider(color: AppColors.gray100, height: 1),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _tableRow({
    required String month,
    required String income,
    required String expense,
    required String netWorth,
    bool isHeader = false,
  }) {
    final style = isHeader
        ? AppTypography.labelSmall
        : AppTypography.bodySmall.copyWith(color: AppColors.gray700);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(month, style: style)),
          Expanded(
            flex: 2,
            child: Text(income, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(expense, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(netWorth, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Legend helper
  // -----------------------------------------------------------------------

  Widget _buildLegend(List<_LegendItem> items) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(item.label, style: AppTypography.caption),
          ],
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend model
// ---------------------------------------------------------------------------

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_change_indicator.dart';
import '../design_system/components/al_section_header.dart';
import '../design_system/components/al_screen_header.dart';
import '../utils/format_korean_won.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _MonthlyData {
  final String month;
  final double income;
  final double expense;
  final double netCashFlow;
  final double netWorth;
  final double savingsRate;
  final double realEstate; // 부동산
  final double stocks; // 주식투자
  final double cash; // 현금예금
  final double debt; // 대출부채

  const _MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.netCashFlow,
    required this.netWorth,
    required this.savingsRate,
    required this.realEstate,
    required this.stocks,
    required this.cash,
    required this.debt,
  });
}

const _kDummyData = <_MonthlyData>[
  _MonthlyData(
    month: '2025-10',
    income: 530,
    expense: 310,
    netCashFlow: 220,
    netWorth: 2002,
    savingsRate: 41.5,
    realEstate: 1000,
    stocks: 500,
    cash: 912,
    debt: 410,
  ),
  _MonthlyData(
    month: '2025-11',
    income: 545,
    expense: 325,
    netCashFlow: 220,
    netWorth: 2034,
    savingsRate: 40.4,
    realEstate: 1000,
    stocks: 500,
    cash: 938,
    debt: 404,
  ),
  _MonthlyData(
    month: '2025-12',
    income: 620,
    expense: 410,
    netCashFlow: 210,
    netWorth: 2045,
    savingsRate: 33.9,
    realEstate: 1000,
    stocks: 500,
    cash: 945,
    debt: 400,
  ),
  _MonthlyData(
    month: '2026-01',
    income: 535,
    expense: 328,
    netCashFlow: 207,
    netWorth: 2054,
    savingsRate: 38.7,
    realEstate: 1000,
    stocks: 500,
    cash: 952,
    debt: 398,
  ),
  _MonthlyData(
    month: '2026-02',
    income: 540,
    expense: 332,
    netCashFlow: 208,
    netWorth: 2063,
    savingsRate: 38.5,
    realEstate: 1000,
    stocks: 500,
    cash: 961,
    debt: 398,
  ),
  _MonthlyData(
    month: '2026-03',
    income: 535,
    expense: 342,
    netCashFlow: 193,
    netWorth: 2098,
    savingsRate: 36.1,
    realEstate: 1000,
    stocks: 500,
    cash: 988,
    debt: 390,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String _selectedPeriod = '6m';

  List<_MonthlyData> get _data {
    if (_selectedPeriod == '6m') {
      return _kDummyData.length > 6
          ? _kDummyData.sublist(_kDummyData.length - 6)
          : _kDummyData;
    }
    return _kDummyData;
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
                  // Key metrics
                  _buildKeyMetrics(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Net worth trend
                  _buildNetWorthTrendCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Income vs expense
                  _buildIncomeExpenseCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Cash flow
                  _buildCashFlowCard(),
                  SizedBox(height: AppSpacing.sectionGap),

                  // Savings rate trend
                  _buildSavingsRateCard(),
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
        _periodButton('6m', '6개월'),
        SizedBox(width: AppSpacing.sm),
        _periodButton('12m', '12개월'),
      ],
    );
  }

  Widget _periodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald600 : AppColors.gray100,
          borderRadius: AppRadius.fullAll,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Key metrics (2-col grid)
  // -----------------------------------------------------------------------

  Widget _buildKeyMetrics() {
    return Row(
      children: [
        Expanded(
          child: AlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('순자산', style: AppTypography.labelSmall),
                SizedBox(height: AppSpacing.sm),
                Text('20.9억', style: AppTypography.amountMedium),
                SizedBox(height: AppSpacing.xs),
                AlChangeIndicator.percent(percent: 1.7),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: AlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('저축률', style: AppTypography.labelSmall),
                SizedBox(height: AppSpacing.sm),
                Text('36.1%', style: AppTypography.amountMedium),
                SizedBox(height: AppSpacing.xs),
                AlChangeIndicator(
                  value: '2.4%p',
                  isPositive: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Chart helpers
  // -----------------------------------------------------------------------

  List<String> get _monthLabels => _data.map((d) => formatMonth(d.month)).toList();

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

  FlTitlesData _baseTitles({
    Widget Function(double, TitleMeta)? leftTitleWidget,
    double leftReservedSize = 48,
  }) {
    return FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx < 0 || idx >= _data.length) return SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                _monthLabels[idx],
                style: AppTypography.caption,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReservedSize,
          getTitlesWidget: leftTitleWidget ??
              (value, meta) {
                return Text(
                  formatChartWon(value),
                  style: AppTypography.caption,
                );
              },
        ),
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
    final spots = _data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netWorth))
        .toList();

    final minY = _data.map((d) => d.netWorth).reduce((a, b) => a < b ? a : b) - 50;
    final maxY = _data.map((d) => d.netWorth).reduce((a, b) => a > b ? a : b) + 50;

    return _chartCard(
      title: '순자산 추이',
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_data.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: _defaultGrid,
          borderData: _noBorder,
          titlesData: _baseTitles(),
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
              dotData: FlDotData(show: false),
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
  }

  // -----------------------------------------------------------------------
  // 2) Income vs Expense - Grouped Bar Chart (emerald + red)
  // -----------------------------------------------------------------------

  Widget _buildIncomeExpenseCard() {
    final groups = _data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: e.value.income,
            color: AppColors.emerald500,
            width: 12,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: e.value.expense,
            color: AppColors.red600,
            width: 12,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return _chartCard(
      title: '수입 vs 지출',
      legend: _buildLegend([
        _LegendItem('수입', AppColors.emerald500),
        _LegendItem('지출', AppColors.red600),
      ]),
      chart: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: _defaultGrid,
          borderData: _noBorder,
          titlesData: _baseTitles(),
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
  }

  // -----------------------------------------------------------------------
  // 3) Cash Flow - Line Chart (blue)
  // -----------------------------------------------------------------------

  Widget _buildCashFlowCard() {
    final spots = _data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netCashFlow))
        .toList();

    final minY = _data.map((d) => d.netCashFlow).reduce((a, b) => a < b ? a : b) - 20;
    final maxY = _data.map((d) => d.netCashFlow).reduce((a, b) => a > b ? a : b) + 20;

    return _chartCard(
      title: '월별 현금 흐름',
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_data.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: _defaultGrid,
          borderData: _noBorder,
          titlesData: _baseTitles(),
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
              color: AppColors.blue600,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.blue600,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // 4) Savings Rate - Line Chart (purple), Y 0-50%
  // -----------------------------------------------------------------------

  Widget _buildSavingsRateCard() {
    final spots = _data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.savingsRate))
        .toList();

    return _chartCard(
      title: '저축률 추이',
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: (_data.length - 1).toDouble(),
          minY: 0,
          maxY: 50,
          gridData: _defaultGrid,
          borderData: _noBorder,
          titlesData: _baseTitles(
            leftTitleWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: AppTypography.caption,
              );
            },
            leftReservedSize: 36,
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.gray800,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.y.toStringAsFixed(1)}%',
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
              color: AppColors.purple600,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.purple600,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // 5) Asset Category - Stacked Bar Chart
  // -----------------------------------------------------------------------

  Widget _buildAssetCategoryCard() {
    final groups = _data.asMap().entries.map((e) {
      final d = e.value;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: d.realEstate + d.stocks + d.cash,
            width: 20,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: [
              BarChartRodStackItem(0, d.realEstate, AppColors.blue600),
              BarChartRodStackItem(
                d.realEstate,
                d.realEstate + d.stocks,
                AppColors.green500,
              ),
              BarChartRodStackItem(
                d.realEstate + d.stocks,
                d.realEstate + d.stocks + d.cash,
                AppColors.purple600,
              ),
            ],
            color: Colors.transparent,
          ),
          // Debt as separate negative-ish rod shown in red
          BarChartRodData(
            toY: d.debt,
            width: 20,
            color: AppColors.red600,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();

    return _chartCard(
      title: '월별 자산 추이',
      legend: _buildLegend([
        _LegendItem('부동산', AppColors.blue600),
        _LegendItem('주식', AppColors.green500),
        _LegendItem('현금', AppColors.purple600),
        _LegendItem('부채', AppColors.red600),
      ]),
      chart: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: _defaultGrid,
          borderData: _noBorder,
          titlesData: _baseTitles(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.gray800,
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final d = _data[groupIdx];
                if (rodIdx == 0) {
                  return BarTooltipItem(
                    '자산 ${formatChartWon(d.realEstate + d.stocks + d.cash)}',
                    TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return BarTooltipItem(
                  '부채 ${formatChartWon(d.debt)}',
                  TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // 6) Monthly detail table
  // -----------------------------------------------------------------------

  Widget _buildMonthlyDetailTable() {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(title: '월별 상세 내역'),
          SizedBox(height: AppSpacing.lg),
          // Header row
          _tableRow(
            month: '월',
            income: '수입',
            expense: '지출',
            netWorth: '순자산',
            isHeader: true,
          ),
          Divider(color: AppColors.gray200, height: 1),
          ..._data.map((d) {
            return Column(
              children: [
                _tableRow(
                  month: formatMonth(d.month),
                  income: formatChartWon(d.income),
                  expense: formatChartWon(d.expense),
                  netWorth: formatChartWon(d.netWorth),
                ),
                Divider(color: AppColors.gray100, height: 1),
              ],
            );
          }),
        ],
      ),
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

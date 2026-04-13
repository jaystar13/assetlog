import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_async_button.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_stat_row.dart';
import '../design_system/components/al_change_indicator.dart';
import '../design_system/components/al_section_header.dart';
import '../models/models.dart';
import '../core/notifiers/home_notifier.dart';
import '../core/providers.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/format_korean_won.dart';
import '../utils/snackbar_helper.dart';
import '../utils/user_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _goalAnimController;
  late final Animation<double> _goalAnim;

  final _prefs = UserPreferences();

  // Goal setting controllers
  final _goalStartController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _goalDeadlineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);

    // 목표 달성률 애니메이션
    _goalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _goalAnim = CurvedAnimation(
      parent: _goalAnimController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _goalAnimController.forward();
    });
  }

  @override
  void dispose() {
    _goalAnimController.dispose();
    _prefs.removeListener(_onPrefsChanged);
    _goalStartController.dispose();
    _goalAmountController.dispose();
    _goalDeadlineController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildDailyQuote(DailyQuote? quote) {
    if (quote == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald50, Colors.white],
        ),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.emerald100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.quote, size: 20, color: AppColors.emerald400),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '— ${quote.author}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.emerald600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 가장 최근에 로드된 dashboard 데이터 (bottom sheet 등에서 참조용)
  HomeDashboard? _lastDashboard;

  void _showGoalSettingSheet() {
    final goal = _lastDashboard?.goal;
    _goalStartController.text = goal?.startAmount.toString() ?? '';
    _goalAmountController.text = goal?.targetAmount.toString() ?? '';
    _goalDeadlineController.text = goal?.deadline ?? '';

    AlBottomSheet.show(
      context: context,
      title: '목표 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('자산 목표를 설정하고 달성률을 추적하세요.', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          AlInput(
            label: '시작 금액',
            placeholder: '목표 시작 시점의 자산 금액',
            prefixIcon: Icon(
              LucideIcons.flag,
              size: 16,
              color: AppColors.gray500,
            ),
            controller: _goalStartController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
          ),
          const SizedBox(height: AppSpacing.lg),
          AlInput(
            label: '목표 금액',
            placeholder: '목표 금액을 입력하세요',
            prefixIcon: Icon(
              LucideIcons.target,
              size: 16,
              color: AppColors.gray500,
            ),
            controller: _goalAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
          ),
          const SizedBox(height: AppSpacing.lg),
          AlInput(
            label: '목표 기한',
            placeholder: 'YYYY-MM-DD',
            prefixIcon: Icon(
              LucideIcons.calendar,
              size: 16,
              color: AppColors.gray500,
            ),
            controller: _goalDeadlineController,
          ),
          const SizedBox(height: AppSpacing.xl),
          AlAsyncButton(
            label: '저장',
            onPressed: () async {
              final startAmount = CurrencyInputFormatter.parse(_goalStartController.text);
              final targetAmount = CurrencyInputFormatter.parse(_goalAmountController.text);
              final deadline = _goalDeadlineController.text.trim();

              if (startAmount == null || targetAmount == null || deadline.isEmpty) {
                showErrorSnackBar(context, '모든 항목을 입력해 주세요');
                return;
              }

              await ref.read(homeNotifierProvider.notifier).saveGoal(
                    startAmount: startAmount,
                    targetAmount: targetAmount,
                    deadline: deadline,
                  );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              showSuccessSnackBar(context, '목표가 설정되었습니다');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(homeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('데이터를 불러올 수 없습니다', style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => ref.invalidate(homeNotifierProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (dashboard) {
          _lastDashboard = dashboard;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: AppSpacing.bottomNavSafeArea),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildDailyQuote(dashboard.dailyQuote),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildGoalVisualizerCard(dashboard),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildNetWorthCard(dashboard),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildMonthlyCashFlowCard(dashboard),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildSharedAssetsSection(dashboard),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === Header ===
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.xl,
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald600, AppColors.emerald700],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Log',
                      style: AppTypography.heading1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _prefs.subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/more/profile'),
                child: Builder(
                  builder: (context) {
                    final user = ref.watch(authNotifierProvider).user;
                    final avatar = user?['avatar'] as String?;
                    final name = user?['name'] as String? ?? '?';
                    final initial = name.isNotEmpty
                        ? name.characters.first
                        : '?';

                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        image: avatar != null
                            ? DecorationImage(
                                image: NetworkImage(avatar),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: avatar == null
                          ? Text(
                              initial,
                              style: AppTypography.label.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === Goal Visualizer Card ===
  Widget _buildGoalVisualizerCard(HomeDashboard dashboard) {
    final goal = dashboard.goal;
    final goalStart = goal?.startAmount ?? 0;
    final goalTarget = goal?.targetAmount ?? 0;
    final remaining = goalTarget - dashboard.netWorth;
    final range = goalTarget - goalStart;
    final progress = dashboard.netWorth - goalStart;
    final fraction = range > 0 ? (progress / range).clamp(0.0, 1.0) : 0.0;

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(
            title: '목표 달성률',
            actionLabel: '목표 설정',
            onAction: _showGoalSettingSheet,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 출발 / 현재 / 목표 라벨 행 ──
          AnimatedBuilder(
            animation: _goalAnim,
            builder: (context, _) {
              final animatedFraction = fraction * _goalAnim.value;
              return Column(
                children: [
                  // 마커 라벨 행
                  SizedBox(
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 시작 라벨
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.flag,
                                    size: 12,
                                    color: AppColors.gray500,
                                  ),
                                  SizedBox(width: 3),
                                  Text('시작', style: AppTypography.caption),
                                ],
                              ),
                              Text(
                                formatKoreanWon(goalStart),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 목표 라벨
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.target,
                                    size: 12,
                                    color: AppColors.emerald600,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '목표',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.emerald600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formatKoreanWon(goalTarget),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 프로그레스 바 ──
                  SizedBox(
                    height: 32,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        final markerX = barWidth * animatedFraction;

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            // 배경 바
                            Container(
                              height: 10,
                              width: barWidth,
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: AppRadius.fullAll,
                              ),
                            ),
                            // 채워진 바 (그라데이션)
                            Container(
                              height: 10,
                              width: markerX.clamp(0.0, barWidth),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.fullAll,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.emerald400,
                                    AppColors.emerald600,
                                  ],
                                ),
                              ),
                            ),
                            // 현재 위치 마커 (발광 효과)
                            Positioned(
                              left: (markerX - 10).clamp(0.0, barWidth - 20),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.emerald600,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.emerald600.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── 달성률 퍼센트 & 현재 금액 ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: Text(
                          '${(animatedFraction * 100).toStringAsFixed(1)}% 달성',
                          style: AppTypography.label.copyWith(
                            color: AppColors.emerald700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatKoreanWon(dashboard.netWorth),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── 남은 금액 메시지 ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.flag, size: 14, color: AppColors.emerald600),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  remaining > 0
                      ? '목표까지 ${formatKoreanWon(remaining)} 남았어요!'
                      : '목표를 달성했어요!',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 기한 표시
          Center(
            child: Text(
              '목표 기한: ${goal?.deadline ?? '-'}',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }

  // === Net Worth Card ===
  Widget _buildNetWorthCard(HomeDashboard dashboard) {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(title: '순자산'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKoreanWon(dashboard.netWorth),
                style: AppTypography.amountLarge,
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AlChangeIndicator.percent(
                  percent: dashboard.netWorthChangePercent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AlStatRow(
            dotColor: AppColors.blue600,
            label: '총 자산',
            value: formatKoreanWon(dashboard.totalAssets),
            valueColor: AppColors.blue600,
            backgroundColor: AppColors.blue50,
          ),
          const SizedBox(height: AppSpacing.sm),
          AlStatRow(
            dotColor: AppColors.red600,
            label: '총 부채',
            value: formatKoreanWon(dashboard.totalDebts),
            valueColor: AppColors.red600,
            backgroundColor: AppColors.red50,
          ),
          if (dashboard.lastMonthNetWorth != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: dashboard.netWorthGrowth >= 0 ? AppColors.emerald50 : AppColors.red50,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Icon(
                    dashboard.netWorthGrowth >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 16,
                    color: dashboard.netWorthGrowth >= 0 ? AppColors.emerald600 : AppColors.red600,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '전월 대비 ${dashboard.netWorthGrowth >= 0 ? '+' : ''}${formatKoreanWon(dashboard.netWorthGrowth)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: dashboard.netWorthGrowth >= 0 ? AppColors.emerald700 : AppColors.red700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // === Monthly Cash Flow Card ===
  Widget _buildMonthlyCashFlowCard(HomeDashboard dashboard) {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(
            title: '${DateTime.now().month}월 현금 흐름',
            actionLabel: '상세보기',
            onAction: () => context.go('/cashflow'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수입', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(dashboard.monthlyIncome),
                      style: AppTypography.amountSmall.copyWith(
                        color: AppColors.emerald600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('지출', style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(dashboard.monthlyExpense),
                      style: AppTypography.amountSmall.copyWith(
                        color: AppColors.red600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value:
                  (dashboard.monthlyIncome > 0
                          ? dashboard.monthlyExpense /
                                dashboard.monthlyIncome
                          : 0.0)
                      .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                dashboard.monthlyExpense > dashboard.monthlyIncome
                    ? AppColors.red600
                    : AppColors.emerald500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '지출 비율: ${dashboard.monthlyIncome > 0 ? (dashboard.monthlyExpense / dashboard.monthlyIncome * 100).round() : 0}%',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  // === Shared Assets Section ===
  Widget _buildSharedAssetsSection(HomeDashboard dashboard) {
    final sharedGroups = dashboard.sharedGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlSectionHeader(
          title: '공유받은 자산',
          actionLabel: '전체 보기',
          onAction: () => context.go('/more/groups'),
        ),
        const SizedBox(height: AppSpacing.md),
        if (sharedGroups.isEmpty)
          AlCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(LucideIcons.users, size: 36, color: AppColors.gray300),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '공유 그룹이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...sharedGroups.map(_buildGroupCard),
      ],
    );
  }

  Widget _buildGroupCard(SharedGroupSummary group) {
    return GestureDetector(
      onTap: () => context.push('/more/groups/${group.groupId}'),
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: AlCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(LucideIcons.users, size: 22, color: AppColors.emerald600),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.groupName, style: AppTypography.label),
                    SizedBox(height: 2),
                    Text(
                      '멤버 ${group.memberCount}명 · 공유 ${group.sharedItemCount}건',
                      style: AppTypography.caption.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}


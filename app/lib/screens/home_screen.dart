import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/radius.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_button.dart';
import '../design_system/components/al_bottom_sheet.dart';
import '../design_system/components/al_input.dart';
import '../design_system/components/al_stat_row.dart';
import '../design_system/components/al_change_indicator.dart';
import '../design_system/components/al_section_header.dart';
import '../models/models.dart';
import '../core/notifiers/home_notifier.dart';
import '../core/providers.dart';
import '../repositories/repositories.dart';
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
  final _repo = HomeRepository();
  late final List<SharedAssetInfo> _sharedAssets;
  late final List<DailyQuote> _quotes;

  // Goal setting controllers
  final _goalStartController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _goalDeadlineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sharedAssets = _repo.getSharedAssets();
    _quotes = _repo.getQuotes();
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

  DailyQuote get _todayQuote {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  Widget _buildDailyQuote() {
    final quote = _todayQuote;
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
          SizedBox(width: AppSpacing.md),
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
                SizedBox(height: AppSpacing.sm),
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

  void _showSubtitleEditDialog() {
    final controller = TextEditingController(text: _prefs.subtitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('한 줄 소개', style: AppTypography.heading3),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: '나만의 한 줄 소개를 입력하세요',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray400,
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald600),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.gray600)),
          ),
          TextButton(
            onPressed: () {
              _prefs.setSubtitle(controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text('저장', style: TextStyle(color: AppColors.emerald600)),
          ),
        ],
      ),
    );
  }

  // dashboard 데이터 헬퍼 — build()에서 세팅
  HomeDashboard? _dashboard;

  void _showGoalSettingSheet() {
    final goal = _dashboard?.goal;
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
          SizedBox(height: AppSpacing.xl),
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
          SizedBox(height: AppSpacing.lg),
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
          SizedBox(height: AppSpacing.lg),
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
          SizedBox(height: AppSpacing.xl),
          AlButton(
            label: '저장',
            onPressed: () async {
              final startAmount = CurrencyInputFormatter.parse(_goalStartController.text);
              final targetAmount = CurrencyInputFormatter.parse(_goalAmountController.text);
              final deadline = _goalDeadlineController.text.trim();

              if (startAmount == null || targetAmount == null || deadline.isEmpty) {
                showErrorSnackBar(context, '모든 항목을 입력해 주세요');
                return;
              }

              Navigator.of(context).pop();

              await ref.read(homeNotifierProvider.notifier).saveGoal(
                    startAmount: startAmount,
                    targetAmount: targetAmount,
                    deadline: deadline,
                  );
              if (mounted) showSuccessSnackBar(context, '목표가 설정되었습니다');
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
        error: (e, _) => Center(child: Text('데이터를 불러올 수 없습니다')),
        data: (dashboard) {
          _dashboard = dashboard;
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
                      SizedBox(height: AppSpacing.lg),
                      _buildDailyQuote(),
                      SizedBox(height: AppSpacing.sectionGap),
                      _buildGoalVisualizerCard(),
                      SizedBox(height: AppSpacing.sectionGap),
                      _buildNetWorthCard(),
                      SizedBox(height: AppSpacing.sectionGap),
                      _buildMonthlyCashFlowCard(),
                      SizedBox(height: AppSpacing.sectionGap),
                      _buildSharedAssetsSection(),
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
                    SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: _showSubtitleEditDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _prefs.subtitle,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.pencil,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
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
  Widget _buildGoalVisualizerCard() {
    final goal = _dashboard!.goal;
    final goalStart = goal?.startAmount ?? 0;
    final goalTarget = goal?.targetAmount ?? 0;
    final remaining = goalTarget - _dashboard!.netWorth;
    final range = goalTarget - goalStart;
    final progress = _dashboard!.netWorth - goalStart;
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
          SizedBox(height: AppSpacing.xl),

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

                  SizedBox(height: AppSpacing.md),

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
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        formatKoreanWon(_dashboard!.netWorth),
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

          SizedBox(height: AppSpacing.lg),

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
                SizedBox(width: AppSpacing.sm),
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

          SizedBox(height: AppSpacing.sm),

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
  Widget _buildNetWorthCard() {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(title: '순자산'),
          SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKoreanWon(_dashboard!.netWorth),
                style: AppTypography.amountLarge,
              ),
              SizedBox(width: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AlChangeIndicator.percent(
                  percent: _dashboard!.netWorthChangePercent,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AlStatRow(
            dotColor: AppColors.blue600,
            label: '총 자산',
            value: formatKoreanWon(_dashboard!.totalAssets),
            valueColor: AppColors.blue600,
            backgroundColor: AppColors.blue50,
          ),
          SizedBox(height: AppSpacing.sm),
          AlStatRow(
            dotColor: AppColors.red600,
            label: '총 부채',
            value: formatKoreanWon(_dashboard!.totalDebts),
            valueColor: AppColors.red600,
            backgroundColor: AppColors.red50,
          ),
          if (_dashboard!.lastMonthNetWorth != null) ...[
            SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _dashboard!.netWorthGrowth >= 0 ? AppColors.emerald50 : AppColors.red50,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Icon(
                    _dashboard!.netWorthGrowth >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 16,
                    color: _dashboard!.netWorthGrowth >= 0 ? AppColors.emerald600 : AppColors.red600,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '전월 대비 ${_dashboard!.netWorthGrowth >= 0 ? '+' : ''}${formatKoreanWon(_dashboard!.netWorthGrowth)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: _dashboard!.netWorthGrowth >= 0 ? AppColors.emerald700 : AppColors.red700,
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
  Widget _buildMonthlyCashFlowCard() {
    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlSectionHeader(
            title: '${DateTime.now().month}월 현금 흐름',
            actionLabel: '상세보기',
            onAction: () => context.go('/cashflow'),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수입', style: AppTypography.bodySmall),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(_dashboard!.monthlyIncome),
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
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      formatKoreanWon(_dashboard!.monthlyExpense),
                      style: AppTypography.amountSmall.copyWith(
                        color: AppColors.red600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: LinearProgressIndicator(
              value:
                  (_dashboard!.monthlyIncome > 0
                          ? _dashboard!.monthlyExpense /
                                _dashboard!.monthlyIncome
                          : 0.0)
                      .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _dashboard!.monthlyExpense > _dashboard!.monthlyIncome
                    ? AppColors.red600
                    : AppColors.emerald500,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '지출 비율: ${_dashboard!.monthlyIncome > 0 ? (_dashboard!.monthlyExpense / _dashboard!.monthlyIncome * 100).round() : 0}%',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  // === Shared Assets Section ===
  Widget _buildSharedAssetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlSectionHeader(
          title: '공유받은 자산',
          actionLabel: '전체 보기',
          onAction: () => context.go('/more/access'),
        ),
        SizedBox(height: AppSpacing.md),
        if (_sharedAssets.isEmpty)
          AlCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(LucideIcons.users, size: 36, color: AppColors.gray300),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      '공유받은 자산이 없습니다',
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
          ..._sharedAssets.map(_buildSharedAssetCard),
      ],
    );
  }

  Widget _buildSharedAssetCard(SharedAssetInfo shared) {
    final totalAssets = shared.totalAssets;
    final totalDebt = shared.totalDebt;
    final netWorth = shared.netWorth;

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아바타 + 이름 + 업데이트일
          Row(
            children: [
              AlAvatar.medium(
                text: shared.ownerAvatar,
                gradientColors: [AppColors.emerald400, AppColors.teal500],
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shared.ownerName}님의 자산',
                      style: AppTypography.label,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${shared.lastUpdated} 업데이트',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.gray400,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),

          // 자산 요약: 3열
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                _buildSharedStat('총 자산', totalAssets, AppColors.emerald600),
                _buildSharedStatDivider(),
                _buildSharedStat('부채', totalDebt, AppColors.red600),
                _buildSharedStatDivider(),
                _buildSharedStat('순자산', netWorth, AppColors.blue600),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // 권한 요약
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  size: 14,
                  color: AppColors.emerald600,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shared.permissions,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.emerald700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedStat(String label, int value, Color color) {
    String formatted;
    if (value >= 100000000) {
      final billions = value / 100000000;
      formatted = '${billions.toStringAsFixed(1)}억';
    } else {
      formatted = formatKoreanWon(value);
    }

    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.caption),
          SizedBox(height: 4),
          Text(
            formatted,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedStatDivider() {
    return Container(width: 1, height: 32, color: AppColors.gray200);
  }
}

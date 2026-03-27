import 'package:flutter/material.dart';
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
import '../utils/format_korean_won.dart';
import '../utils/snackbar_helper.dart';
import '../utils/user_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _goalAnimController;
  late final Animation<double> _goalAnim;

  final _prefs = UserPreferences();

  // --- Dummy data ---
  final int goalStartAmount = 1500000000; // 목표 출발 금액 (15억)
  final int goalAmount = 3000000000;
  final String goalDeadline = '2030-12-31';
  final int currentNetWorth = 2160000000;
  final int totalAssets = 2580000000;
  final int totalDebts = 420000000;
  final int lastMonthNetWorth = 2100000000;
  final int monthlyIncome = 5350000;
  final int monthlyExpense = 3420000;
  final String currentMonth = '3월';

  // 공유받은 자산 더미 데이터
  final List<Map<String, dynamic>> _sharedAssets = [
    {
      'ownerName': '홍아버지',
      'ownerAvatar': '👨‍🦳',
      'ownerEmail': 'dad@example.com',
      'permissions': '수입/지출: 편집 · 자산: 부동산, 주식 편집 가능',
      'totalAssets': 3250000000,
      'totalDebt': 180000000,
      'netWorth': 3070000000,
      'lastUpdated': '2026-03-25',
    },
  ];

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

  // ── 일일 격언 ──
  static const _quotes = [
    {'text': '부는 쓰는 것을 아끼는 데서 시작된다.', 'author': '키케로'},
    {'text': '돈을 모으는 것은 나무를 심는 것과 같다. 시간이 최고의 비료다.', 'author': '워런 버핏'},
    {'text': '작은 지출을 조심하라. 작은 구멍이 큰 배를 침몰시킨다.', 'author': '벤자민 프랭클린'},
    {'text': '부자가 되는 비결은 내일 할 일을 오늘 하고, 오늘 먹을 것을 내일 먹는 것이다.', 'author': '마크 트웨인'},
    {'text': '투자의 첫 번째 규칙은 돈을 잃지 않는 것이고, 두 번째 규칙은 첫 번째 규칙을 잊지 않는 것이다.', 'author': '워런 버핏'},
    {'text': '저축은 미래의 나에게 보내는 선물이다.', 'author': '작자 미상'},
    {'text': '복리는 세계 8번째 불가사의다. 이해하는 자는 벌고, 모르는 자는 지불한다.', 'author': '알베르트 아인슈타인'},
    {'text': '재정적 자유는 사치가 아니라 선택의 자유다.', 'author': '로버트 기요사키'},
    {'text': '수입의 일부를 먼저 저축하라. 스스로에게 먼저 지불하라.', 'author': '조지 클레이슨'},
    {'text': '돈은 좋은 하인이지만 나쁜 주인이다.', 'author': '프랜시스 베이컨'},
    {'text': '기회는 준비된 자에게 온다. 오늘의 기록이 내일의 부를 만든다.', 'author': '루이 파스퇴르'},
    {'text': '시작이 반이다. 오늘 한 걸음이 내일의 자산이 된다.', 'author': '아리스토텔레스'},
    {'text': '부를 쌓는 것은 마라톤이지 단거리 경주가 아니다.', 'author': '데이브 램지'},
    {'text': '당신이 잠자는 동안에도 돈이 일하게 하라.', 'author': '워런 버핏'},
    {'text': '목표 없는 항해에 순풍은 없다.', 'author': '세네카'},
    {'text': '지출을 줄이는 것은 수입을 늘리는 것만큼 가치 있다.', 'author': '토머스 풀러'},
    {'text': '오늘의 결정이 10년 후의 나를 만든다.', 'author': '작자 미상'},
    {'text': '꾸준함은 재능을 이긴다. 매일 조금씩이 기적을 만든다.', 'author': '작자 미상'},
    {'text': '가장 좋은 투자는 자기 자신에 대한 투자다.', 'author': '워런 버핏'},
    {'text': '부자는 돈을 관리하고, 가난한 자는 돈에 관리당한다.', 'author': 'T. 하브 에커'},
    {'text': '현명한 사람은 돈을 벌면 먼저 저축하고 나머지로 생활한다.', 'author': '짐 론'},
    {'text': '경제적 독립은 자유로운 삶의 초석이다.', 'author': '작자 미상'},
    {'text': '지금 시작하지 않으면 1년 후에도 같은 자리에 있을 것이다.', 'author': '카렌 램'},
    {'text': '부의 축적에서 가장 강력한 힘은 시간과 인내다.', 'author': '찰리 멍거'},
    {'text': '재산을 지키는 것은 재산을 모으는 것보다 더 어렵다.', 'author': '오비디우스'},
    {'text': '위험을 감수하지 않는 것이 가장 큰 위험이다.', 'author': '마크 저커버그'},
    {'text': '성공은 매일 반복하는 작은 노력의 합이다.', 'author': '로버트 콜리어'},
    {'text': '절약은 큰 수입이다.', 'author': '키케로'},
    {'text': '당신의 순자산은 자존감이 아니다. 하지만 관리할 가치는 있다.', 'author': '수지 오먼'},
    {'text': '미래는 오늘 우리가 무엇을 하느냐에 달려 있다.', 'author': '마하트마 간디'},
    {'text': '부는 능력이 아니라 습관에서 온다.', 'author': '작자 미상'},
  ];

  Map<String, String> get _todayQuote {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
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
          colors: [
            AppColors.emerald50,
            Colors.white,
          ],
        ),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.emerald100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.quote,
            size: 20,
            color: AppColors.emerald400,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote['text']!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray800,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '— ${quote['author']}',
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
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.gray400),
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

  double get goalPercent =>
      goalAmount > 0 ? (currentNetWorth / goalAmount * 100).clamp(0, 100) : 0;

  double get netWorthChangePercent {
    if (lastMonthNetWorth == 0) return 0;
    return (currentNetWorth - lastMonthNetWorth) / lastMonthNetWorth * 100;
  }

  int get netWorthGrowth => currentNetWorth - lastMonthNetWorth;

  double get cashFlowRatio =>
      monthlyIncome > 0 ? monthlyExpense / monthlyIncome : 0;

  void _showGoalSettingSheet() {
    _goalStartController.text = goalStartAmount.toString();
    _goalAmountController.text = goalAmount.toString();
    _goalDeadlineController.text = goalDeadline;

    AlBottomSheet.show(
      context: context,
      title: '목표 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자산 목표를 설정하고 달성률을 추적하세요.',
            style: AppTypography.bodyMedium,
          ),
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
            onPressed: () {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: AppSpacing.bottomNavSafeArea),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.lg),
                  _buildDailyQuote(),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildGoalVisualizerCard(),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildNetWorthCard(),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildGrowthInsightCard(),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildMonthlyCashFlowCard(),
                  SizedBox(height: AppSpacing.sectionGap),
                  _buildSharedAssetsSection(),
                ],
              ),
            ),
          ],
        ),
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
                      style: AppTypography.heading1.copyWith(color: Colors.white),
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
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '홍',
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
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
    final remaining = goalAmount - currentNetWorth;
    final range = goalAmount - goalStartAmount;
    final progress = currentNetWorth - goalStartAmount;
    final fraction = range > 0
        ? (progress / range).clamp(0.0, 1.0)
        : 0.0;

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
                                  Icon(LucideIcons.flag, size: 12, color: AppColors.gray500),
                                  SizedBox(width: 3),
                                  Text('시작', style: AppTypography.caption),
                                ],
                              ),
                              Text(formatKoreanWon(goalStartAmount), style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
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
                                  Icon(LucideIcons.target, size: 12, color: AppColors.emerald600),
                                  SizedBox(width: 3),
                                  Text('목표', style: AppTypography.caption.copyWith(
                                    color: AppColors.emerald600,
                                  )),
                                ],
                              ),
                              Text(formatKoreanWon(goalAmount), style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald600,
                              )),
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
                                      color: AppColors.emerald600.withValues(alpha: 0.3),
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
                        formatKoreanWon(currentNetWorth),
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
              '목표 기한: $goalDeadline',
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
                formatKoreanWon(currentNetWorth),
                style: AppTypography.amountLarge,
              ),
              SizedBox(width: AppSpacing.sm),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AlChangeIndicator.percent(
                  percent: netWorthChangePercent,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          AlStatRow(
            dotColor: AppColors.blue600,
            label: '총 자산',
            value: formatKoreanWon(totalAssets),
            valueColor: AppColors.blue600,
            backgroundColor: AppColors.blue50,
          ),
          SizedBox(height: AppSpacing.sm),
          AlStatRow(
            dotColor: AppColors.red600,
            label: '총 부채',
            value: formatKoreanWon(totalDebts),
            valueColor: AppColors.red600,
            backgroundColor: AppColors.red50,
          ),
        ],
      ),
    );
  }

  // === Growth Insight Card ===
  Widget _buildGrowthInsightCard() {
    return AlCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.emerald500, AppColors.teal500],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(
              LucideIcons.trendingUp,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지난달 대비 성장',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '+${formatKoreanWon(netWorthGrowth)}',
                  style: AppTypography.amountMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
            title: '$currentMonth 현금 흐름',
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
                      formatKoreanWon(monthlyIncome),
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
                      formatKoreanWon(monthlyExpense),
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
              value: cashFlowRatio.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                cashFlowRatio > 1 ? AppColors.red600 : AppColors.emerald500,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '지출 비율: ${(cashFlowRatio * 100).round()}%',
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

  Widget _buildSharedAssetCard(Map<String, dynamic> shared) {
    final totalAssets = shared['totalAssets'] as int;
    final totalDebt = shared['totalDebt'] as int;
    final netWorth = shared['netWorth'] as int;

    return AlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아바타 + 이름 + 업데이트일
          Row(
            children: [
              AlAvatar.medium(
                text: shared['ownerAvatar'] as String,
                gradientColors: [AppColors.emerald400, AppColors.teal500],
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shared['ownerName']}님의 자산',
                      style: AppTypography.label,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${shared['lastUpdated']} 업데이트',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: AppColors.gray400),
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
                Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.emerald600),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shared['permissions'] as String,
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
    return Container(
      width: 1,
      height: 32,
      color: AppColors.gray200,
    );
  }

}

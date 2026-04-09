import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/components/al_card.dart';
import '../design_system/components/al_avatar.dart';
import '../design_system/components/al_month_selector.dart';
import '../design_system/components/al_screen_header.dart';
import '../design_system/components/al_stat_row.dart';
import '../models/models.dart';
import '../core/providers.dart';
import '../utils/format_korean_won.dart';

class SharedAssetDetailScreen extends ConsumerStatefulWidget {
  final String accessId;
  final String ownerName;
  final String? ownerAvatar;
  final String cashflowPermission;
  final Map<String, String> assetPermissions;

  const SharedAssetDetailScreen({
    super.key,
    required this.accessId,
    required this.ownerName,
    this.ownerAvatar,
    required this.cashflowPermission,
    required this.assetPermissions,
  });

  @override
  ConsumerState<SharedAssetDetailScreen> createState() =>
      _SharedAssetDetailScreenState();
}

class _SharedAssetDetailScreenState
    extends ConsumerState<SharedAssetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  // 데이터
  List<Map<String, dynamic>> _assets = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  bool get _hasAssetPermission =>
      widget.assetPermissions.values.any((v) => v != 'none');
  bool get _hasCashflowPermission => widget.cashflowPermission != 'none';

  int get _tabCount {
    int count = 0;
    if (_hasAssetPermission) count++;
    if (_hasCashflowPermission) count++;
    return count;
  }

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final service = ref.read(sharedAccessServiceProvider);

    try {
      final futures = <Future>[];
      if (_hasAssetPermission) {
        futures.add(service.getSharedAssets(widget.accessId, month: _monthKey));
      }
      if (_hasCashflowPermission) {
        futures.add(_loadTransactions());
      }

      final results = await Future.wait(futures);

      int idx = 0;
      if (_hasAssetPermission) {
        _assets = (results[idx] as List).cast<Map<String, dynamic>>();
        idx++;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    final service = ref.read(sharedAccessServiceProvider);
    try {
      final response = await service.getSharedTransactions(widget.accessId, month: _monthKey);
      _transactions = response.map((raw) => Transaction.fromMap(raw)).toList();
    } catch (_) {
      _transactions = [];
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  // ─── 자산 합계 계산 ──────────────────────────

  num get _totalAssets {
    num total = 0;
    for (final asset in _assets) {
      final catId = asset['categoryId'] as String;
      if (catId == 'loans') continue;
      final history = asset['valueHistory'] as List<dynamic>? ?? [];
      if (history.isNotEmpty) total += (history.first['value'] as num);
    }
    return total;
  }

  num get _totalDebts {
    num total = 0;
    for (final asset in _assets) {
      final catId = asset['categoryId'] as String;
      if (catId != 'loans') continue;
      final history = asset['valueHistory'] as List<dynamic>? ?? [];
      if (history.isNotEmpty) total += (history.first['value'] as num).abs();
    }
    return total;
  }

  num get _netWorth => _totalAssets - _totalDebts;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[];
    final tabViews = <Widget>[];

    if (_hasAssetPermission) {
      tabs.add(Tab(text: '자산'));
      tabViews.add(_buildAssetTab());
    }
    if (_hasCashflowPermission) {
      tabs.add(Tab(text: '수입/지출'));
      tabViews.add(_buildTransactionTab());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AlScreenHeader(
            title: '${widget.ownerName}님의 자산',
            showBack: true,
          ),

          // 순자산 요약
          _buildSummaryCard(),

          // 월 선택기
          AlMonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _goToNextMonth,
          ),

          // 탭
          if (_tabCount > 1)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.emerald600,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.emerald600,
                indicatorWeight: 2,
                labelStyle: AppTypography.label,
                tabs: tabs,
              ),
            ),

          // 콘텐츠
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _tabCount > 1
                    ? TabBarView(
                        controller: _tabController,
                        children: tabViews,
                      )
                    : tabViews.isNotEmpty
                        ? tabViews.first
                        : Center(
                            child: Text('접근 권한이 없습니다',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.gray500)),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AlAvatar.medium(
            text: widget.ownerName.isNotEmpty
                ? widget.ownerName.characters.first
                : '?',
            imageUrl: widget.ownerAvatar,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('순자산', style: AppTypography.caption),
                Text(
                  formatKoreanWon(_netWorth),
                  style: AppTypography.amountMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('자산 ${formatKoreanWon(_totalAssets)}',
                  style: AppTypography.caption.copyWith(color: AppColors.blue600)),
              Text('부채 ${formatKoreanWon(_totalDebts)}',
                  style: AppTypography.caption.copyWith(color: AppColors.red600)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 자산 탭 ──────────────────────────────────

  Widget _buildAssetTab() {
    if (_assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wallet, size: 48, color: AppColors.gray300),
            SizedBox(height: AppSpacing.md),
            Text('자산 데이터가 없습니다',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
          ],
        ),
      );
    }

    // 카테고리별 그룹핑
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final asset in _assets) {
      final catId = asset['categoryId'] as String;
      grouped.putIfAbsent(catId, () => []).add(asset);
    }

    final categoryConfig = {
      'real-estate': (name: '부동산', icon: LucideIcons.home, color: AppColors.blue600),
      'stocks': (name: '주식', icon: LucideIcons.trendingUp, color: AppColors.green600),
      'cash': (name: '현금', icon: LucideIcons.banknote, color: AppColors.purple600),
      'loans': (name: '부채', icon: LucideIcons.creditCard, color: AppColors.red600),
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: grouped.entries.map((entry) {
          final catId = entry.key;
          final items = entry.value;
          final config = categoryConfig[catId];

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: AlCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(config?.icon ?? LucideIcons.folder,
                          size: 18, color: config?.color ?? AppColors.gray600),
                      SizedBox(width: AppSpacing.sm),
                      Text(config?.name ?? catId, style: AppTypography.heading3),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  ...items.map((asset) {
                    final history = asset['valueHistory'] as List<dynamic>? ?? [];
                    final value = history.isNotEmpty
                        ? (history.first['value'] as num)
                        : 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(asset['name'] as String,
                              style: AppTypography.bodyMedium),
                          Text(formatKoreanWon(value),
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 수입/지출 탭 ─────────────────────────────

  Widget _buildTransactionTab() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: AppColors.gray300),
            SizedBox(height: AppSpacing.md),
            Text('거래 내역이 없습니다',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.gray500)),
          ],
        ),
      );
    }

    final income = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amount);
    final expense = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수입/지출 요약 바
          AlCard(
            child: Row(
              children: [
                Expanded(
                  child: AlStatRow(
                    dotColor: AppColors.emerald500,
                    label: '수입',
                    value: formatKoreanWon(income),
                    valueColor: AppColors.emerald600,
                    backgroundColor: AppColors.emerald50,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AlStatRow(
                    dotColor: AppColors.red600,
                    label: '지출',
                    value: formatKoreanWon(expense),
                    valueColor: AppColors.red600,
                    backgroundColor: AppColors.red50,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // 거래 리스트
          ..._transactions.map((tx) {
            final isIncome = tx.type == TransactionType.income;
            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlCard(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.name, style: AppTypography.bodyMedium),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${tx.category} · ${tx.subCategory}',
                            style: AppTypography.caption,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            tx.date.length >= 10
                                ? tx.date.substring(0, 10)
                                : tx.date,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}${formatKoreanWon(tx.amount)}',
                      style: AppTypography.amountSmall.copyWith(
                        color:
                            isIncome ? AppColors.emerald600 : AppColors.red600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/daily_quote.dart';
import '../../models/enums.dart';
import '../../models/transaction.dart';
import '../../utils/date_format.dart';
import '../providers.dart';

class FinancialGoal {
  final num startAmount;
  final num targetAmount;
  final String deadline;

  const FinancialGoal({
    required this.startAmount,
    required this.targetAmount,
    required this.deadline,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
        startAmount: json['startAmount'] as num,
        targetAmount: json['targetAmount'] as num,
        deadline: () {
          final d = json['deadline'] as String;
          return d.length >= 10 ? d.substring(0, 10) : d;
        }(),
      );
}

class SharedGroupSummary {
  final String groupId;
  final String groupName;
  final int memberCount;
  final int sharedItemCount;

  const SharedGroupSummary({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.sharedItemCount,
  });
}

class HomeDashboard {
  final num totalAssets;
  final num totalDebts;
  final num netWorth;
  final num? lastMonthNetWorth;
  final int monthlyIncome;
  final int monthlyExpense;
  final FinancialGoal? goal;
  final DailyQuote? dailyQuote;
  final List<SharedGroupSummary> sharedGroups;

  const HomeDashboard({
    required this.totalAssets,
    required this.totalDebts,
    required this.netWorth,
    this.lastMonthNetWorth,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.goal,
    this.dailyQuote,
    this.sharedGroups = const [],
  });

  num get netWorthGrowth =>
      lastMonthNetWorth != null ? netWorth - lastMonthNetWorth! : 0;

  double get netWorthChangePercent {
    if (lastMonthNetWorth == null || lastMonthNetWorth == 0) return 0;
    return (netWorthGrowth / lastMonthNetWorth!.abs()) * 100;
  }
}

class HomeNotifier extends AutoDisposeAsyncNotifier<HomeDashboard> {
  @override
  Future<HomeDashboard> build() async {
    final assetService = ref.watch(assetServiceProvider);
    final txService = ref.watch(transactionServiceProvider);
    final authService = ref.watch(authServiceProvider);
    final groupService = ref.watch(shareGroupServiceProvider);
    final quoteService = ref.watch(quoteServiceProvider);

    final now = DateTime.now();
    final currentMonth = toMonthKey(now);

    // 전월 계산
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = toMonthKey(lastMonthDate);

    // 병렬 호출 — 개별 실패 시 기본값으로 대체
    final futures = await Future.wait([
      assetService.getAssets(month: currentMonth).catchError((_) => <Map<String, dynamic>>[]),
      assetService.getAssets(month: lastMonth).catchError((_) => <Map<String, dynamic>>[]),
      txService.getTransactions(month: currentMonth).catchError((_) => <Transaction>[]),
      authService.getGoal().catchError((_) => null),
      groupService.getMyGroups().catchError((_) => <Map<String, dynamic>>[]),
      quoteService.getDailyQuote().catchError((_) => null),
    ]);

    final currentAssets = futures[0] as List<Map<String, dynamic>>;
    final lastMonthAssets = futures[1] as List<Map<String, dynamic>>;
    final transactions = futures[2] as List<Transaction>;
    final goalData = futures[3] as Map<String, dynamic>?;
    final groups = futures[4] as List<Map<String, dynamic>>;
    final quote = futures[5] as DailyQuote?;

    // 당월 자산 합계
    final currentTotals = _calcAssetTotals(currentAssets);

    // 전월 자산 합계
    final lastTotals = _calcAssetTotals(lastMonthAssets);
    final lastMonthNetWorth = lastTotals.assets - lastTotals.debts;

    // 월간 수입/지출
    int income = 0;
    int expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    // 그룹 요약
    final groupSummaries = groups.map((g) {
      final members = (g['members'] as List?)?.length ?? 0;
      final itemCount = (g['_count'] as Map<String, dynamic>?)?['sharedItems'] ?? 0;
      return SharedGroupSummary(
        groupId: g['id'] as String,
        groupName: g['name'] as String,
        memberCount: members,
        sharedItemCount: itemCount as int,
      );
    }).toList();

    return HomeDashboard(
      totalAssets: currentTotals.assets,
      totalDebts: currentTotals.debts,
      netWorth: currentTotals.assets - currentTotals.debts,
      lastMonthNetWorth: lastMonthNetWorth != 0 ? lastMonthNetWorth : null,
      monthlyIncome: income,
      monthlyExpense: expense,
      goal: goalData != null ? FinancialGoal.fromJson(goalData) : null,
      dailyQuote: quote,
      sharedGroups: groupSummaries,
    );
  }

  ({num assets, num debts}) _calcAssetTotals(List<Map<String, dynamic>> rawAssets) {
    num assets = 0;
    num debts = 0;
    for (final asset in rawAssets) {
      final history = asset['valueHistory'] as List<dynamic>? ?? [];
      if (history.isEmpty) continue;
      final value = (history.first['value'] as num);
      final categoryId = asset['categoryId'] as String;
      if (categoryId == 'loans') {
        debts += value.abs();
      } else {
        assets += value;
      }
    }
    return (assets: assets, debts: debts);
  }

  Future<void> saveGoal({
    required int startAmount,
    required int targetAmount,
    required String deadline,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.upsertGoal(
      startAmount: startAmount,
      targetAmount: targetAmount,
      deadline: deadline,
    );
    ref.invalidateSelf();
  }
}

final homeNotifierProvider =
    AsyncNotifierProvider.autoDispose<HomeNotifier, HomeDashboard>(
  HomeNotifier.new,
);

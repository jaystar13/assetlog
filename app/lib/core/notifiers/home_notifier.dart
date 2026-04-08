import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/transaction.dart';
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
        deadline: (json['deadline'] as String).substring(0, 10),
      );
}

class HomeDashboard {
  final num totalAssets;
  final num totalDebts;
  final num netWorth;
  final num? lastMonthNetWorth;
  final int monthlyIncome;
  final int monthlyExpense;
  final FinancialGoal? goal;

  const HomeDashboard({
    required this.totalAssets,
    required this.totalDebts,
    required this.netWorth,
    this.lastMonthNetWorth,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.goal,
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

    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 전월 계산
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';

    // 병렬 호출: 당월 자산, 전월 자산, 당월 거래, 목표
    final results = await Future.wait([
      assetService.getAssets(month: currentMonth),
      assetService.getAssets(month: lastMonth),
      txService.getTransactions(month: currentMonth),
      authService.getGoal(),
    ]);

    final currentAssets = results[0] as List<Map<String, dynamic>>;
    final lastMonthAssets = results[1] as List<Map<String, dynamic>>;
    final transactions = results[2] as List<Transaction>;
    final goalData = results[3] as Map<String, dynamic>?;

    // 당월 자산 합계
    final currentTotals = _calcAssetTotals(currentAssets);

    // 전월 자산 합계
    final lastTotals = _calcAssetTotals(lastMonthAssets);
    final lastMonthNetWorth = lastTotals.assets - lastTotals.debts;

    // 월간 수입/지출 — Transaction 객체로 반환됨
    int income = 0;
    int expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return HomeDashboard(
      totalAssets: currentTotals.assets,
      totalDebts: currentTotals.debts,
      netWorth: currentTotals.assets - currentTotals.debts,
      lastMonthNetWorth: lastMonthNetWorth != 0 ? lastMonthNetWorth : null,
      monthlyIncome: income,
      monthlyExpense: expense,
      goal: goalData != null ? FinancialGoal.fromJson(goalData) : null,
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

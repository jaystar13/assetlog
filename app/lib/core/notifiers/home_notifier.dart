import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final int monthlyIncome;
  final int monthlyExpense;
  final FinancialGoal? goal;

  const HomeDashboard({
    required this.totalAssets,
    required this.totalDebts,
    required this.netWorth,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.goal,
  });
}

class HomeNotifier extends AutoDisposeAsyncNotifier<HomeDashboard> {
  @override
  Future<HomeDashboard> build() async {
    final assetService = ref.watch(assetServiceProvider);
    final txService = ref.watch(transactionServiceProvider);
    final authService = ref.watch(authServiceProvider);

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 병렬 호출
    final results = await Future.wait([
      assetService.getAssets(),
      txService.getTransactions(month: month),
      authService.getGoal(),
    ]);

    final assets = results[0] as List<Map<String, dynamic>>;
    final transactions = results[1];
    final goalData = results[2] as Map<String, dynamic>?;

    // 자산 합계
    num totalAssets = 0;
    num totalDebts = 0;
    for (final asset in assets) {
      final history = asset['valueHistory'] as List<dynamic>? ?? [];
      final value = history.isNotEmpty ? (history.first['value'] as num) : 0;
      final categoryId = asset['categoryId'] as String;
      if (categoryId == 'loans') {
        totalDebts += value.abs();
      } else {
        totalAssets += value;
      }
    }

    // 월간 수입/지출
    final txList = transactions as List<dynamic>;
    int income = 0;
    int expense = 0;
    for (final tx in txList) {
      if (tx is Map<String, dynamic>) {
        final type = tx['type'] as String?;
        final amount = (tx['amount'] as num?)?.toInt() ?? 0;
        if (type == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }
    }

    return HomeDashboard(
      totalAssets: totalAssets,
      totalDebts: totalDebts,
      netWorth: totalAssets - totalDebts,
      monthlyIncome: income,
      monthlyExpense: expense,
      goal: goalData != null ? FinancialGoal.fromJson(goalData) : null,
    );
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

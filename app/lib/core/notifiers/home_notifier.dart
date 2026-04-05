import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class HomeDashboard {
  final num totalAssets;
  final num totalDebts;
  final num netWorth;
  final int monthlyIncome;
  final int monthlyExpense;

  const HomeDashboard({
    required this.totalAssets,
    required this.totalDebts,
    required this.netWorth,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });
}

class HomeNotifier extends AutoDisposeAsyncNotifier<HomeDashboard> {
  @override
  Future<HomeDashboard> build() async {
    final assetService = ref.watch(assetServiceProvider);
    final txService = ref.watch(transactionServiceProvider);

    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 병렬 호출
    final results = await Future.wait([
      assetService.getAssets(),
      txService.getTransactions(month: month),
    ]);

    final assets = results[0] as List<Map<String, dynamic>>;
    final transactions = results[1];

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
    );
  }
}

final homeNotifierProvider =
    AsyncNotifierProvider.autoDispose<HomeNotifier, HomeDashboard>(
  HomeNotifier.new,
);

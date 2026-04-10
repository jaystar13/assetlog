import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../providers.dart';
import 'home_notifier.dart';

class TransactionNotifier extends AutoDisposeFamilyAsyncNotifier<List<Transaction>, String> {
  late TransactionService _service;

  @override
  Future<List<Transaction>> build(String month) async {
    _service = ref.watch(transactionServiceProvider);
    return _service.getTransactions(month: month);
  }

  Future<void> addTransaction({
    required String type,
    required String name,
    required int amount,
    required String date,
    required String category,
    required String subCategory,
    String? paymentMethod,
    String? targetMonth,
    List<String>? shareGroupIds,
  }) async {
    await _service.createTransaction(
      type: type,
      name: name,
      amount: amount,
      date: date,
      category: category,
      subCategory: subCategory,
      paymentMethod: paymentMethod,
      targetMonth: targetMonth,
      shareGroupIds: shareGroupIds,
    );
    _invalidateAll();
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _service.updateTransaction(id, data);
    _invalidateAll();
  }

  Future<void> deleteTransaction(String id) async {
    await _service.deleteTransaction(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidateSelf();
    ref.invalidate(homeNotifierProvider);
  }
}

final transactionNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<TransactionNotifier, List<Transaction>, String>(
  TransactionNotifier.new,
);

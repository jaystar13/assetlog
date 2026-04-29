import 'enums.dart';

class Transaction {
  final String id;
  final TransactionType type;
  final String targetMonth; // "YYYY-MM"
  final String category;
  final String subCategory;
  final int amount;
  final String? note;
  final List<String> shareGroupIds;

  const Transaction({
    required this.id,
    required this.type,
    required this.targetMonth,
    required this.category,
    required this.subCategory,
    required this.amount,
    this.note,
    this.shareGroupIds = const [],
  });

  bool get isShared => shareGroupIds.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.value,
        'targetMonth': targetMonth,
        'category': category,
        'subCategory': subCategory,
        'amount': amount,
        'note': note,
        'shareGroupIds': shareGroupIds,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        type: TransactionType.fromString(map['type'] as String),
        targetMonth: (map['targetMonth'] ?? map['target_month']) as String,
        category: map['category'] as String,
        subCategory: (map['subCategory'] ?? map['sub_category']) as String,
        amount: (map['amount'] as num).toInt(),
        note: map['note'] as String?,
        shareGroupIds:
            ((map['shareGroupIds'] as List?)?.cast<String>()) ?? const [],
      );
}

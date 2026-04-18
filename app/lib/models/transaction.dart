import 'enums.dart';

class Transaction {
  final String id;
  final TransactionType type;
  final String targetMonth; // "YYYY-MM"
  final String category;
  final String subCategory;
  final int amount;
  final String? note;

  const Transaction({
    required this.id,
    required this.type,
    required this.targetMonth,
    required this.category,
    required this.subCategory,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.value,
        'targetMonth': targetMonth,
        'category': category,
        'subCategory': subCategory,
        'amount': amount,
        'note': note,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        type: TransactionType.fromString(map['type'] as String),
        targetMonth: (map['targetMonth'] ?? map['target_month']) as String,
        category: map['category'] as String,
        subCategory: (map['subCategory'] ?? map['sub_category']) as String,
        amount: (map['amount'] as num).toInt(),
        note: map['note'] as String?,
      );
}

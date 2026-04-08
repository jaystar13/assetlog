import 'enums.dart';

class Transaction {
  final String id;
  final TransactionType type;
  final String name;
  final int amount;
  final String date;
  final String category;
  final String subCategory;
  final String? paymentMethod;
  final String? editedBy;

  const Transaction({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    required this.subCategory,
    this.paymentMethod,
    this.editedBy,
  });

  /// _ManualEntryForm 호환용 Map 변환
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.value,
        'name': name,
        'amount': amount,
        'date': date,
        'category': category,
        'subCategory': subCategory,
        'paymentMethod': paymentMethod,
        'editedBy': editedBy,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        type: TransactionType.fromString(map['type'] as String),
        name: map['name'] as String,
        amount: (map['amount'] as num).toInt(),
        date: map['date'] as String,
        category: map['category'] as String,
        subCategory: map['subCategory'] as String,
        paymentMethod: map['paymentMethod'] as String?,
        editedBy: map['editedBy'] as String?,
      );
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─── Transaction Type ────────────────────────────────────────────────────────

enum TransactionType {
  income('income', '수입'),
  expense('expense', '지출');

  const TransactionType(this.value, this.label);
  final String value;
  final String label;

  static TransactionType fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => income);
}

// ─── Permission Level ────────────────────────────────────────────────────────

enum PermissionLevel {
  none('none', '없음'),
  view('view', '보기'),
  edit('edit', '편집');

  const PermissionLevel(this.value, this.label);
  final String value;
  final String label;

  PermissionLevel next() {
    switch (this) {
      case none:
        return view;
      case view:
        return edit;
      case edit:
        return none;
    }
  }

  static PermissionLevel fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => none);
}

// ─── Invitation Status ───────────────────────────────────────────────────────

enum InvitationStatus {
  pending('pending', '대기중'),
  accepted('accepted', '수락됨'),
  declined('declined', '거절됨'),
  expired('expired', '만료됨');

  const InvitationStatus(this.value, this.label);
  final String value;
  final String label;

  static InvitationStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => pending);
}

// ─── Asset Category Type ─────────────────────────────────────────────────────

enum AssetCategoryType {
  realEstate(
    id: 'real-estate',
    koreanName: '부동산',
    colorKey: 'blue',
  ),
  stocks(
    id: 'stocks',
    koreanName: '주식/투자',
    colorKey: 'green',
  ),
  cash(
    id: 'cash',
    koreanName: '현금/예금',
    colorKey: 'purple',
  ),
  loans(
    id: 'loans',
    koreanName: '대출/부채',
    colorKey: 'red',
  );

  const AssetCategoryType({
    required this.id,
    required this.koreanName,
    required this.colorKey,
  });

  final String id;
  final String koreanName;
  final String colorKey;

  IconData get icon {
    switch (this) {
      case realEstate:
        return LucideIcons.building2;
      case stocks:
        return LucideIcons.trendingUp;
      case cash:
        return LucideIcons.wallet;
      case loans:
        return LucideIcons.creditCard;
    }
  }

  static AssetCategoryType fromId(String id) =>
      values.firstWhere((e) => e.id == id, orElse: () => realEstate);
}

// ─── Period Filter ───────────────────────────────────────────────────────────

enum PeriodFilter {
  sixMonths('6m', '6개월'),
  twelveMonths('12m', '12개월');

  const PeriodFilter(this.value, this.label);
  final String value;
  final String label;

  static PeriodFilter fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => sixMonths);
}

// ─── Income / Expense Category ───────────────────────────────────────────────

enum IncomeCategory {
  salary('Salary', '급여'),
  financial('Financial', '금융'),
  business('Business', '사업');

  const IncomeCategory(this.value, this.label);
  final String value;
  final String label;

  static IncomeCategory fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => salary);
}

enum ExpenseCategory {
  essential('Essential', '필수'),
  optional('Optional', '선택'),
  living('Living', '생활');

  const ExpenseCategory(this.value, this.label);
  final String value;
  final String label;

  static ExpenseCategory fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => essential);
}

// ─── Payment Method ──────────────────────────────────────────────────────────

enum PaymentMethod {
  creditCard('신용카드'),
  bankTransfer('계좌이체'),
  cash('현금');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromString(String s) =>
      values.firstWhere((e) => e.label == s, orElse: () => creditCard);
}

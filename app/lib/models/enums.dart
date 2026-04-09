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
  threeMonths('3m', '3개월'),
  sixMonths('6m', '6개월');

  const PeriodFilter(this.value, this.label);
  final String value;
  final String label;

  static PeriodFilter fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => sixMonths);
}

// ─── Income / Expense Category ───────────────────────────────────────────────

enum IncomeCategory {
  salary('급여', '급여');

  const IncomeCategory(this.value, this.label);
  final String value;
  final String label;

  static IncomeCategory fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => salary);
}

enum ExpenseCategory {
  living('생활비', '생활비'),
  essential('필수비', '필수비'),
  optional('선택비', '선택비'),
  investment('투자비', '투자비');

  const ExpenseCategory(this.value, this.label);
  final String value;
  final String label;

  static ExpenseCategory fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => living);
}

// ─── Category - SubCategory Map ──────────────────────────────────────────────

const Map<String, List<String>> categorySubCategoryMap = {
  '급여': ['급여', '인센티브', 'PI', '정산환급', '연차보상'],
  '생활비': ['생활', '주유'],
  '필수비': ['교육', '교통', '의료', '통신', '주거(관리비)', '세금', '경조사', '명절'],
  '선택비': ['여행', '문화'],
  '투자비': ['구독(AI)', '구독(인프라)', '대출(원금)', '대출(이자)'],
};

// ─── Payment Method ──────────────────────────────────────────────────────────
// payment-method.constants.ts (백엔드)와 value 값이 반드시 일치해야 합니다.

enum PaymentMethod {
  // 카드사
  shinhan('신한카드'),
  kbNational('KB국민카드'),
  hyundai('현대카드'),
  samsung('삼성카드'),
  lotte('롯데카드'),
  hana('하나카드'),
  nhNongHyup('NH농협카드'),
  woori('우리카드'),
  bc('BC카드'),
  // 카드 외 지출 수단
  bankTransfer('계좌이체'),
  cash('현금'),
  // 수입 계좌
  salaryAccount('급여계좌'),
  pensionAccount('퇴직연금계좌'),
  investmentAccount('투자수익계좌'),
  sideIncomeAccount('부수입계좌');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod? fromString(String s) =>
      values.where((e) => e.value == s).firstOrNull;
}

// 카드사 목록 (지출 - 신용카드 선택 시 사용)
const List<PaymentMethod> cardCompanies = [
  PaymentMethod.shinhan,
  PaymentMethod.kbNational,
  PaymentMethod.hyundai,
  PaymentMethod.samsung,
  PaymentMethod.lotte,
  PaymentMethod.hana,
  PaymentMethod.nhNongHyup,
  PaymentMethod.woori,
  PaymentMethod.bc,
];

// 카드 외 지출 수단
const List<PaymentMethod> expensePaymentMethods = [
  PaymentMethod.bankTransfer,
  PaymentMethod.cash,
];

// 수입 계좌
const List<PaymentMethod> incomeAccounts = [
  PaymentMethod.salaryAccount,
  PaymentMethod.pensionAccount,
  PaymentMethod.investmentAccount,
  PaymentMethod.sideIncomeAccount,
];

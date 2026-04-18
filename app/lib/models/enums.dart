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
  declined('declined', '거절'),
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

// ─── Group Role ─────────────────────────────────────────────────────────────

enum GroupRole {
  admin('admin', '관리자'),
  viewer('viewer', '뷰어');

  const GroupRole(this.value, this.label);
  final String value;
  final String label;

  static GroupRole fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => viewer);
}

// ─── Income / Expense Category ───────────────────────────────────────────────
// 백엔드 create-transaction.dto.ts의 CATEGORY_SUBCATEGORY_MAP과 반드시 일치.

const List<String> incomeCategories = [
  '근로소득',
  '사업·프리랜서',
  '금융수익',
  '부동산수익',
  '기타수입',
];

const List<String> expenseCategories = [
  '생활비',
  '필수비',
  '선택비',
  '투자비',
];

const Map<String, List<String>> categorySubCategoryMap = {
  // 수입
  '근로소득': ['급여', '인센티브', '상여', '기타'],
  '사업·프리랜서': ['사업소득', '프리랜서', '기타'],
  '금융수익': ['배당', '이자', '매매차익', '기타'],
  '부동산수익': ['임대료', '매매차익', '기타'],
  '기타수입': ['기타'],
  // 지출
  '생활비': ['식비', '카페·간식', '쇼핑·의류', '외식·술자리', '기타생활'],
  '필수비': ['주거·관리비', '교통·통신', '교육', '건강·의료', '보험', '기타필수'],
  '선택비': ['여가·취미', '여행', '구독서비스', '경조사', '기타선택'],
  '투자비': ['저축·예적금', '주식·펀드', '부동산', '기타투자'],
};


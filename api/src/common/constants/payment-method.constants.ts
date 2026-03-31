// 결제수단 단일 진실 공급원 (Single Source of Truth)
// Flutter models/enums.dart의 PaymentMethod enum과 값이 일치해야 합니다.

// ── 카드사 ────────────────────────────────────────────────────────────────────
// CardCompany seed 데이터의 name 값과 반드시 일치해야 합니다.
export const CARD_COMPANIES = [
  '신한카드',
  'KB국민카드',
  '현대카드',
  '삼성카드',
  '롯데카드',
  '하나카드',
  'NH농협카드',
  '우리카드',
  'BC카드',
] as const;

// ── 카드 외 지출 수단 ─────────────────────────────────────────────────────────
export const OTHER_EXPENSE_METHODS = ['계좌이체', '현금'] as const;

// ── 수입 계좌 ─────────────────────────────────────────────────────────────────
export const INCOME_ACCOUNTS = [
  '급여계좌',
  '퇴직연금계좌',
  '투자수익계좌',
  '부수입계좌',
] as const;

// ── 전체 (DTO 검증용) ─────────────────────────────────────────────────────────
export const ALL_PAYMENT_METHODS = [
  ...CARD_COMPANIES,
  ...OTHER_EXPENSE_METHODS,
  ...INCOME_ACCOUNTS,
] as const;

export type PaymentMethod = (typeof ALL_PAYMENT_METHODS)[number];

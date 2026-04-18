import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
} from 'class-validator';

export const TRANSACTION_TYPES = ['income', 'expense'] as const;
export type TransactionType = (typeof TRANSACTION_TYPES)[number];

// ── 카테고리 - 세부카테고리 정의 ──────────────────────────────────────────────

export const CATEGORY_SUBCATEGORY_MAP = {
  // 수입
  근로소득: ['급여', '인센티브', '상여', '기타'],
  '사업·프리랜서': ['사업소득', '프리랜서', '기타'],
  금융수익: ['배당', '이자', '매매차익', '기타'],
  부동산수익: ['임대료', '매매차익', '기타'],
  기타수입: ['기타'],
  // 지출
  생활비: ['식비', '카페·간식', '쇼핑·의류', '외식·술자리', '기타생활'],
  필수비: ['주거·관리비', '교통·통신', '교육', '건강·의료', '보험', '기타필수'],
  선택비: ['여가·취미', '여행', '구독서비스', '경조사', '기타선택'],
  투자비: ['저축·예적금', '주식·펀드', '부동산', '기타투자'],
} as const;

export const INCOME_CATEGORIES = [
  '근로소득',
  '사업·프리랜서',
  '금융수익',
  '부동산수익',
  '기타수입',
] as const;

export const EXPENSE_CATEGORIES = [
  '생활비',
  '필수비',
  '선택비',
  '투자비',
] as const;

export const ALL_CATEGORIES = [
  ...INCOME_CATEGORIES,
  ...EXPENSE_CATEGORIES,
] as const;

export const ALL_SUBCATEGORIES = Object.values(
  CATEGORY_SUBCATEGORY_MAP,
).flat() as string[];

export class CreateTransactionDto {
  @ApiProperty({ enum: TRANSACTION_TYPES, example: 'expense' })
  @IsIn(TRANSACTION_TYPES)
  type: TransactionType;

  @ApiProperty({ example: '2026-04', description: '귀속월 (YYYY-MM)' })
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, {
    message: 'targetMonth는 YYYY-MM 형식이어야 합니다.',
  })
  targetMonth: string;

  @ApiProperty({ enum: ALL_CATEGORIES, example: '생활비' })
  @IsIn(ALL_CATEGORIES)
  category: string;

  @ApiProperty({ example: '식비', description: '세부 카테고리' })
  @IsIn(ALL_SUBCATEGORIES)
  subCategory: string;

  @ApiProperty({ example: 2000000, description: '금액 (원)' })
  @IsInt()
  @Min(0)
  amount: number;

  @ApiPropertyOptional({ example: '외식 포함', description: '비고 (선택)' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;

  @ApiPropertyOptional({
    example: ['group-uuid-1'],
    description: '공유할 그룹 ID 목록',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  shareGroupIds?: string[];
}

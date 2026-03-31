import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Min } from 'class-validator';
import { ALL_PAYMENT_METHODS } from '../../common/constants/payment-method.constants';

export const TRANSACTION_TYPES = ['income', 'expense'] as const;
export type TransactionType = (typeof TRANSACTION_TYPES)[number];

// ── 카테고리 - 세부카테고리 정의 ──────────────────────────────────────────────

export const CATEGORY_SUBCATEGORY_MAP = {
  // 수입
  급여: ['급여', '인센티브', 'PI', '정산환급', '연차보상'],
  // 지출
  생활비: ['생활', '주유'],
  필수비: ['교육', '교통', '의료', '통신', '주거(관리비)', '세금', '경조사', '명절'],
  선택비: ['여행', '문화'],
  투자비: ['구독(AI)', '구독(인프라)', '대출(원금)', '대출(이자)'],
} as const;

export const INCOME_CATEGORIES = ['급여'] as const;
export const EXPENSE_CATEGORIES = ['생활비', '필수비', '선택비', '투자비'] as const;
export const ALL_CATEGORIES = [...INCOME_CATEGORIES, ...EXPENSE_CATEGORIES] as const;
export const ALL_SUBCATEGORIES = Object.values(CATEGORY_SUBCATEGORY_MAP).flat() as string[];

export class CreateTransactionDto {
  @ApiProperty({ enum: TRANSACTION_TYPES, example: 'income' })
  @IsIn(TRANSACTION_TYPES)
  type: TransactionType;

  @ApiProperty({ example: '3월 급여' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 3000000, description: '금액 (원)' })
  @IsInt()
  @Min(0)
  amount: number;

  @ApiProperty({ example: '2025-03-25', description: '거래 일자 (YYYY-MM-DD 또는 ISO 형식)' })
  @IsDateString()
  date: string;

  @ApiProperty({ enum: ALL_CATEGORIES, example: '급여' })
  @IsIn(ALL_CATEGORIES)
  category: string;

  @ApiProperty({ example: '급여', description: '세부 카테고리' })
  @IsIn(ALL_SUBCATEGORIES)
  subCategory: string;

  @ApiPropertyOptional({ enum: ALL_PAYMENT_METHODS, example: '신한카드', description: '결제수단' })
  @IsOptional()
  @IsIn(ALL_PAYMENT_METHODS)
  paymentMethod?: string;
}

import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, Matches } from 'class-validator';
import { TRANSACTION_TYPES } from './create-transaction.dto';
import type { TransactionType } from './create-transaction.dto';

export class QueryTransactionDto {
  @ApiPropertyOptional({ example: '2025-03', description: '조회 월 (YYYY-MM)' })
  @IsOptional()
  @Matches(/^\d{4}-(0[1-9]|1[0-2])$/, { message: 'month는 YYYY-MM 형식이어야 합니다.' })
  month?: string;

  @ApiPropertyOptional({ enum: TRANSACTION_TYPES })
  @IsOptional()
  @IsIn(TRANSACTION_TYPES)
  type?: TransactionType;
}

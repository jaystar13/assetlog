import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';

export class UpsertHistoryDto {
  @ApiProperty({ example: 5200000, description: '해당 월의 자산 가치 (원, 부채는 음수)' })
  @IsInt()
  value: number;
}

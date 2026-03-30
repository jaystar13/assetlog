import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, Min } from 'class-validator';

export class UpsertHistoryDto {
  @ApiProperty({ example: 5200000, description: '해당 월의 자산 가치 (원)' })
  @IsNumber()
  @Min(0)
  value: number;
}

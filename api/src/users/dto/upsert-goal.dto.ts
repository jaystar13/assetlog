import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Matches, Min } from 'class-validator';

export class UpsertGoalDto {
  @ApiProperty({ example: 1500000000, description: '시작 금액 (원)' })
  @IsInt()
  @Min(0)
  startAmount: number;

  @ApiProperty({ example: 3000000000, description: '목표 금액 (원)' })
  @IsInt()
  @Min(0)
  targetAmount: number;

  @ApiProperty({ example: '2030-12-31', description: '목표 기한 (YYYY-MM-DD)' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'deadline은 YYYY-MM-DD 형식이어야 합니다.' })
  deadline: string;
}

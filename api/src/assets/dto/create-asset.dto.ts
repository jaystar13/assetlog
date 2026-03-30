import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsNumber, IsString, Min } from 'class-validator';

export const ASSET_CATEGORIES = ['real-estate', 'stocks', 'cash', 'loans'] as const;
export type AssetCategory = (typeof ASSET_CATEGORIES)[number];

export class CreateAssetDto {
  @ApiProperty({ enum: ASSET_CATEGORIES, example: 'cash' })
  @IsIn(ASSET_CATEGORIES)
  categoryId: AssetCategory;

  @ApiProperty({ example: '국민은행 예금' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 5000000, description: '현재 가치 (원)' })
  @IsNumber()
  @Min(0)
  currentValue: number;
}

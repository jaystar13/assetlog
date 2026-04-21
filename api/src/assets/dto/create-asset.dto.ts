import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

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

  @ApiPropertyOptional({ example: '자유 메모', description: '자산 비고 (선택)' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;

  @ApiPropertyOptional({ example: ['group-uuid-1'], description: '공유할 그룹 ID 목록' })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  shareGroupIds?: string[];
}

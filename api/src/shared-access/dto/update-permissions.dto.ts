import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsObject, IsOptional } from 'class-validator';

const PERMISSION_LEVELS = ['none', 'view', 'edit'] as const;

export class UpdatePermissionsDto {
  @ApiPropertyOptional({ enum: PERMISSION_LEVELS, example: 'view', description: '수입/지출 권한' })
  @IsOptional()
  @IsIn(PERMISSION_LEVELS)
  cashflowPermission?: string;

  @ApiPropertyOptional({
    example: { 'real-estate': 'edit', stocks: 'view' },
    description: '자산 카테고리별 권한',
  })
  @IsOptional()
  @IsObject()
  assetPermissions?: Record<string, string>;
}

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

const PERMISSION_LEVELS = ['none', 'view', 'edit'] as const;

export class CreateInvitationDto {
  @ApiProperty({ example: 'user@example.com', description: '초대 대상 이메일' })
  @IsEmail()
  toEmail: string;

  @ApiProperty({ enum: PERMISSION_LEVELS, example: 'view', description: '수입/지출 권한' })
  @IsIn(PERMISSION_LEVELS)
  cashflowPermission: string;

  @ApiProperty({
    example: { 'real-estate': 'edit', stocks: 'view', cash: 'none', loans: 'none' },
    description: '자산 카테고리별 권한',
  })
  @IsObject()
  assetPermissions: Record<string, string>;

  @ApiPropertyOptional({ example: '자산 현황을 공유합니다.', description: '초대 메시지' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  message?: string;
}

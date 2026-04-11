import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class InviteToGroupDto {
  @ApiProperty({ example: 'user@example.com', description: '초대 대상 이메일' })
  @IsEmail()
  toEmail: string;

  @ApiPropertyOptional({ example: '아내', description: '그룹 내 별명' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  nickname?: string;

  @ApiPropertyOptional({ example: '#14B8A6', description: '표시 색상 (hex)' })
  @IsOptional()
  @Matches(/^#[0-9A-Fa-f]{6}$/, { message: 'color는 #RRGGBB 형식이어야 합니다.' })
  color?: string;

  @ApiPropertyOptional({ example: '가족 그룹에 초대합니다', description: '초대 메시지' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  message?: string;
}

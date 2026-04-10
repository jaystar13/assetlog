import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

const ROLES = ['editor', 'viewer'] as const;

export class InviteToGroupDto {
  @ApiProperty({ example: 'user@example.com', description: '초대 대상 이메일' })
  @IsEmail()
  toEmail: string;

  @ApiPropertyOptional({ enum: ROLES, example: 'viewer', description: '부여할 역할' })
  @IsOptional()
  @IsIn(ROLES)
  role?: string;

  @ApiPropertyOptional({ example: '가족 그룹에 초대합니다', description: '초대 메시지' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  message?: string;
}

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class InviteToGroupDto {
  @ApiProperty({ example: 'user@example.com', description: '초대 대상 이메일' })
  @IsEmail()
  toEmail: string;

  @ApiPropertyOptional({ example: '가족 그룹에 초대합니다', description: '초대 메시지' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  message?: string;
}

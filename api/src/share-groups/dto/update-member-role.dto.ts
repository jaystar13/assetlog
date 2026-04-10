import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const ROLES = ['admin', 'editor', 'viewer'] as const;

export class UpdateMemberRoleDto {
  @ApiProperty({ enum: ROLES, example: 'editor', description: '변경할 역할' })
  @IsIn(ROLES)
  role: string;
}

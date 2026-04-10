import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const ROLES = ['admin', 'viewer'] as const;

export class UpdateMemberRoleDto {
  @ApiProperty({ enum: ROLES, example: 'viewer', description: '변경할 역할' })
  @IsIn(ROLES)
  role: string;
}

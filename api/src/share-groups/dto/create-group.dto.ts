import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateGroupDto {
  @ApiProperty({ example: '우리 가족', description: '그룹 이름' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  name: string;
}

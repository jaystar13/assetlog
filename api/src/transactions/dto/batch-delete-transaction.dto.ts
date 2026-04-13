import { IsArray, ArrayMinSize, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class BatchDeleteTransactionDto {
  @ApiProperty({
    description: '삭제할 거래 ID 목록',
    example: ['clxxx1', 'clxxx2'],
  })
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  ids: string[];
}

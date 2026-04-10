import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsIn, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class ShareItemEntry {
  @ApiProperty({ enum: ['transaction', 'asset'], example: 'transaction' })
  @IsIn(['transaction', 'asset'])
  itemType: string;

  @ApiProperty({ example: 'uuid-of-item', description: '거래 또는 자산 ID' })
  @IsString()
  itemId: string;

  @ApiProperty({ enum: ['view', 'edit'], example: 'view', description: '항목별 권한' })
  @IsOptional()
  @IsIn(['view', 'edit'])
  permission?: string;
}

export class ShareItemsDto {
  @ApiProperty({ type: [ShareItemEntry], description: '공유할 항목 목록' })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ShareItemEntry)
  items: ShareItemEntry[];
}

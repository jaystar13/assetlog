import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsIn, IsString } from 'class-validator';

/**
 * 특정 항목(transaction 또는 asset)이 어떤 그룹들에 공유되어야 하는지를 지정해
 * 한 번에 동기화한다. 현재 공유 상태를 새 groupIds 와 비교해 추가/삭제를 모두 처리.
 */
export class SyncItemSharesDto {
  @ApiProperty({ enum: ['transaction', 'asset'], example: 'transaction' })
  @IsIn(['transaction', 'asset'])
  itemType: string;

  @ApiProperty({ example: 'uuid-of-item', description: '거래 또는 자산 ID' })
  @IsString()
  itemId: string;

  @ApiProperty({
    type: [String],
    example: ['group-id-1', 'group-id-2'],
    description: '이 항목을 공유할 그룹 ID 목록 (빈 배열이면 모든 공유 해제)',
  })
  @IsArray()
  @IsString({ each: true })
  groupIds: string[];
}

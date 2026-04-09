import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiQuery, ApiTags } from '@nestjs/swagger';
import { SharedAccessService } from './shared-access.service';
import { UpdatePermissionsDto } from './dto/update-permissions.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('SharedAccess')
@ApiBearerAuth()
@Controller('shared-access')
export class SharedAccessController {
  constructor(private sharedAccessService: SharedAccessService) {}

  @Get()
  @ApiOperation({ summary: '내가 소유자인 공유 멤버 목록' })
  findOwned(@CurrentUser('id') userId: string) {
    return this.sharedAccessService.findOwned(userId);
  }

  @Get('shared-with-me')
  @ApiOperation({ summary: '나에게 공유된 목록' })
  findSharedWithMe(@CurrentUser('id') userId: string) {
    return this.sharedAccessService.findSharedWithMe(userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: '공유 권한 수정 (소유자만)' })
  @ApiParam({ name: 'id', description: '공유 ID' })
  updatePermissions(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdatePermissionsDto,
  ) {
    return this.sharedAccessService.updatePermissions(userId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '공유 해제 (소유자만)' })
  @ApiParam({ name: 'id', description: '공유 ID' })
  remove(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.sharedAccessService.remove(userId, id);
  }

  // ─────────────────────── 공유 데이터 조회 ───────────────────────

  @Get(':id/assets')
  @ApiOperation({ summary: '공유자의 자산 조회 (권한 기반)' })
  @ApiParam({ name: 'id', description: '공유 ID' })
  @ApiQuery({ name: 'month', required: false, description: '기준 월 (YYYY-MM)', example: '2026-04' })
  getSharedAssets(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('month') month?: string,
  ) {
    return this.sharedAccessService.getSharedAssets(userId, id, month);
  }

  @Get(':id/transactions')
  @ApiOperation({ summary: '공유자의 거래 조회 (권한 기반)' })
  @ApiParam({ name: 'id', description: '공유 ID' })
  @ApiQuery({ name: 'month', required: false, description: '기준 월 (YYYY-MM)', example: '2026-04' })
  getSharedTransactions(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('month') month?: string,
  ) {
    return this.sharedAccessService.getSharedTransactions(userId, id, month);
  }
}

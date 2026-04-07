import {
  Controller,
  Get,
  Post,
  Patch,
  Put,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AssetsService } from './assets.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { UpsertHistoryDto } from './dto/upsert-history.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Assets')
@ApiBearerAuth()
@Controller('assets')
export class AssetsController {
  constructor(private assetsService: AssetsService) {}

  @Get()
  @ApiOperation({ summary: '내 자산 목록 조회 (기본: active만)' })
  @ApiQuery({ name: 'status', required: false, enum: ['active', 'closed', 'all'], example: 'active' })
  @ApiQuery({ name: 'month', required: false, description: '기준 월 (YYYY-MM) — 해당 월 이하의 최신 값 반환', example: '2026-04' })
  findAll(
    @CurrentUser('id') userId: string,
    @Query('status') status?: string,
    @Query('month') month?: string,
  ) {
    return this.assetsService.findAll(userId, status === 'all' ? undefined : status, month);
  }

  @Post()
  @ApiOperation({ summary: '자산 추가' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateAssetDto) {
    return this.assetsService.create(userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: '자산 수정' })
  @ApiParam({ name: 'id', description: '자산 ID' })
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateAssetDto,
  ) {
    return this.assetsService.update(userId, id, dto);
  }

  @Patch(':id/close')
  @ApiOperation({ summary: '자산 종료 (soft close — 히스토리 보존)' })
  @ApiParam({ name: 'id', description: '자산 ID' })
  close(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.assetsService.close(userId, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '자산 완전 삭제 (히스토리 포함)' })
  @ApiParam({ name: 'id', description: '자산 ID' })
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.assetsService.remove(userId, id);
  }

  @Get(':id/history')
  @ApiOperation({ summary: '자산 월별 가치 히스토리 조회' })
  @ApiParam({ name: 'id', description: '자산 ID' })
  findHistory(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.assetsService.findHistory(userId, id);
  }

  @Put(':id/history/:month')
  @ApiOperation({ summary: '월별 자산 가치 기록/수정 (month: YYYY-MM)' })
  @ApiParam({ name: 'id', description: '자산 ID' })
  @ApiParam({ name: 'month', description: '월 (YYYY-MM)', example: '2025-01' })
  upsertHistory(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Param('month') month: string,
    @Body() dto: UpsertHistoryDto,
  ) {
    return this.assetsService.upsertHistory(userId, id, month, dto);
  }
}

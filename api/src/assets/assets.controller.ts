import {
  Controller,
  Get,
  Post,
  Patch,
  Put,
  Delete,
  Param,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
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
  @ApiOperation({ summary: '내 자산 목록 조회' })
  findAll(@CurrentUser('id') userId: string) {
    return this.assetsService.findAll(userId);
  }

  @Post()
  @ApiOperation({ summary: '자산 추가 (당월 히스토리 자동 기록)' })
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

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '자산 삭제' })
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
  @ApiOperation({ summary: '특정 월 자산 가치 기록 (B방식 upsert, month: YYYY-MM)' })
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

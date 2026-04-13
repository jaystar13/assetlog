import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { TransactionsService } from './transactions.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { QueryTransactionDto } from './dto/query-transaction.dto';
import { BatchDeleteTransactionDto } from './dto/batch-delete-transaction.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Transactions')
@ApiBearerAuth()
@Controller('transactions')
export class TransactionsController {
  constructor(private transactionsService: TransactionsService) {}

  @Get()
  @ApiOperation({ summary: '수입/지출 목록 조회 (month: YYYY-MM, type: income|expense)' })
  findAll(
    @CurrentUser('id') userId: string,
    @Query() query: QueryTransactionDto,
  ) {
    return this.transactionsService.findAll(userId, query);
  }

  @Post()
  @ApiOperation({ summary: '수입/지출 추가' })
  create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateTransactionDto,
  ) {
    return this.transactionsService.create(userId, dto);
  }

  @Post('batch-delete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '수입/지출 일괄 삭제' })
  batchRemove(
    @CurrentUser('id') userId: string,
    @Body() dto: BatchDeleteTransactionDto,
  ) {
    return this.transactionsService.batchRemove(userId, dto.ids);
  }

  @Patch(':id')
  @ApiOperation({ summary: '수입/지출 수정' })
  @ApiParam({ name: 'id', description: '거래 ID' })
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.transactionsService.update(userId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '수입/지출 삭제' })
  @ApiParam({ name: 'id', description: '거래 ID' })
  remove(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.transactionsService.remove(userId, id);
  }
}

import {
  Controller,
  Post,
  Get,
  UploadedFile,
  UseInterceptors,
  Body,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { ImportService } from './import.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Import')
@ApiBearerAuth()
@Controller('import')
export class ImportController {
  private maxFileSize: number;

  constructor(
    private importService: ImportService,
    private configService: ConfigService,
  ) {
    this.maxFileSize = parseInt(this.configService.get<string>('MAX_UPLOAD_SIZE_MB') ?? '5') * 1024 * 1024;
  }

  @Get('card-companies')
  @ApiOperation({ summary: '파일 임포트 지원 카드사 목록' })
  getSupportedCardCompanies() {
    return this.importService.getSupportedCardCompanies();
  }

  @Post('transactions')
  @UseInterceptors(FileInterceptor('file', { storage: memoryStorage() }))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: '카드 명세서 일괄 업로드 (지출 내역 임포트)' })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['cardCompany', 'targetMonth', 'file'],
      properties: {
        cardCompany: {
          type: 'string',
          example: 'shinhan',
          description: '카드사 (shinhan)',
        },
        targetMonth: {
          type: 'string',
          example: '2026-03',
          description: '귀속월 (YYYY-MM)',
        },
        file: {
          type: 'string',
          format: 'binary',
          description: '카드사 명세서 파일 (.xls)',
        },
      },
    },
  })
  async importTransactions(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('cardCompany') cardCompany: string,
    @Body('targetMonth') targetMonth: string,
  ) {
    if (!file) throw new BadRequestException('파일을 업로드해주세요.');
    if (file.size > this.maxFileSize) {
      const maxMb = Math.round(this.maxFileSize / 1024 / 1024);
      throw new BadRequestException(`파일 크기가 ${maxMb}MB를 초과합니다.`);
    }
    if (!cardCompany) throw new BadRequestException('카드사를 지정해주세요.');
    if (!targetMonth || !/^\d{4}-(0[1-9]|1[0-2])$/.test(targetMonth)) {
      throw new BadRequestException('귀속월을 YYYY-MM 형식으로 입력해주세요.');
    }

    return this.importService.importTransactions(userId, cardCompany, targetMonth, file);
  }
}

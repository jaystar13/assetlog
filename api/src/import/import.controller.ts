import {
  Controller,
  Post,
  Get,
  UploadedFile,
  UseInterceptors,
  Body,
  BadRequestException,
} from '@nestjs/common';
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
  constructor(private importService: ImportService) {}

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
      required: ['cardCompany', 'file'],
      properties: {
        cardCompany: {
          type: 'string',
          example: 'shinhan',
          description: '카드사 (shinhan)',
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
  ) {
    if (!file) throw new BadRequestException('파일을 업로드해주세요.');
    if (!cardCompany) throw new BadRequestException('카드사를 지정해주세요.');

    return this.importService.importTransactions(userId, cardCompany, file);
  }
}

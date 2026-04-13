import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('Quotes')
@ApiBearerAuth()
@Controller('quotes')
export class QuotesController {
  constructor(private prisma: PrismaService) {}

  @Get('daily')
  @ApiOperation({ summary: '오늘의 명언 조회 (날짜 기반 고정 선택)' })
  async getDaily() {
    const count = await this.prisma.dailyQuote.count();
    if (count === 0) return null;

    // 날짜 기반 인덱스: 같은 날엔 같은 명언
    const today = new Date();
    const dayOfYear =
      Math.floor(
        (today.getTime() - new Date(today.getFullYear(), 0, 0).getTime()) /
          86400000,
      );
    const index = dayOfYear % count;

    const quote = await this.prisma.dailyQuote.findMany({
      skip: index,
      take: 1,
    });

    return quote[0] ?? null;
  }

  @Get()
  @ApiOperation({ summary: '전체 명언 목록 조회' })
  findAll() {
    return this.prisma.dailyQuote.findMany();
  }
}

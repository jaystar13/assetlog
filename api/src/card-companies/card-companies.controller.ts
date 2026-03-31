import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('Card Companies')
@ApiBearerAuth()
@Controller('card-companies')
export class CardCompaniesController {
  constructor(private prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: '카드사 목록 조회' })
  findAll() {
    return this.prisma.cardCompany.findMany({
      orderBy: { name: 'asc' },
    });
  }
}

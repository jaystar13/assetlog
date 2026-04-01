import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { parseShinhanXls, type ParsedTransaction } from './parsers/shinhan.parser';
import { parseKbXlsx } from './parsers/kb.parser';
import { CARD_COMPANIES } from '../common/constants/payment-method.constants';

export interface ImportResult {
  total: number;
  imported: number;
  skipped: number;
}

type ParserFn = (buffer: Buffer) => ParsedTransaction[];

// 파서 키 → 카드사명 (payment-method.constants.ts와 일치)
const PARSERS: Record<string, { parse: ParserFn; cardName: (typeof CARD_COMPANIES)[number] }> = {
  shinhan: { parse: parseShinhanXls, cardName: '신한카드' },
  kb: { parse: parseKbXlsx, cardName: 'KB국민카드' },
};

@Injectable()
export class ImportService {
  constructor(private prisma: PrismaService) {}

  async importTransactions(
    userId: string,
    cardCompany: string,
    targetMonth: string,
    file: Express.Multer.File,
  ): Promise<ImportResult> {
    const entry = PARSERS[cardCompany.toLowerCase()];
    if (!entry) {
      throw new BadRequestException(`지원하지 않는 카드사입니다: ${cardCompany}`);
    }

    const parsed = entry.parse(file.buffer);

    if (parsed.length === 0) {
      return { total: 0, imported: 0, skipped: 0 };
    }

    // 카테고리는 기본값으로 저장 — 사용자가 이후 수정 가능
    const DEFAULT_CATEGORY = '생활비';
    const DEFAULT_SUBCATEGORY = '생활';

    const created = await this.prisma.transaction.createMany({
      data: parsed.map((tx) => ({
        userId,
        type: 'expense',
        name: tx.name,
        amount: tx.amount,
        date: new Date(tx.date),
        category: DEFAULT_CATEGORY,
        subCategory: DEFAULT_SUBCATEGORY,
        paymentMethod: entry.cardName,
        targetMonth,
      })),
      skipDuplicates: false,
    });

    return {
      total: parsed.length,
      imported: created.count,
      skipped: parsed.length - created.count,
    };
  }

  getSupportedCardCompanies(): string[] {
    return Object.keys(PARSERS);
  }
}

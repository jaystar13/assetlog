import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { QueryTransactionDto } from './dto/query-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 목록 조회 ───────────────────────

  findAll(userId: string, query: QueryTransactionDto) {
    return this.prisma.transaction.findMany({
      where: {
        userId,
        ...(query.type ? { type: query.type } : {}),
        ...(query.month ? { targetMonth: query.month } : {}),
      },
      orderBy: [{ targetMonth: 'desc' }, { type: 'asc' }, { category: 'asc' }],
    });
  }

  // ─────────────────────── 생성 (누적) ───────────────────────
  // 같은 (type, targetMonth, category, subCategory) 조합이어도 새로운 행으로 추가된다.
  // 세부분류 합계는 UI에서 클라이언트가 계산.

  async create(userId: string, dto: CreateTransactionDto) {
    const transaction = await this.prisma.transaction.create({
      data: {
        userId,
        type: dto.type,
        targetMonth: dto.targetMonth,
        category: dto.category,
        subCategory: dto.subCategory,
        amount: dto.amount,
        note: dto.note ?? null,
      },
    });

    if (dto.shareGroupIds?.length) {
      await this.prisma.sharedItem.createMany({
        data: dto.shareGroupIds.map((groupId) => ({
          groupId,
          ownerUserId: userId,
          itemType: 'transaction',
          itemId: transaction.id,
        })),
        skipDuplicates: true,
      });
    }

    return transaction;
  }

  // ─────────────────────── 수정 ───────────────────────

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    await this.findOneOwned(userId, id);

    return this.prisma.transaction.update({
      where: { id },
      data: {
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.note !== undefined && { note: dto.note }),
      },
    });
  }

  // ─────────────────────── 삭제 ───────────────────────

  async remove(userId: string, id: string) {
    await this.findOneOwned(userId, id);
    await this.prisma.transaction.delete({ where: { id } });
  }

  // ─────────────────────── 일괄 삭제 ───────────────────────

  async batchRemove(userId: string, ids: string[]) {
    const transactions = await this.prisma.transaction.findMany({
      where: { id: { in: ids } },
      select: { id: true, userId: true },
    });

    const foundIds = transactions.map((t) => t.id);
    const notFound = ids.filter((id) => !foundIds.includes(id));
    if (notFound.length > 0) {
      throw new NotFoundException(
        `거래 내역을 찾을 수 없습니다: ${notFound.join(', ')}`,
      );
    }

    const unauthorized = transactions.filter((t) => t.userId !== userId);
    if (unauthorized.length > 0) {
      throw new ForbiddenException('접근 권한이 없는 거래가 포함되어 있습니다.');
    }

    await this.prisma.$transaction([
      this.prisma.sharedItem.deleteMany({
        where: { itemType: 'transaction', itemId: { in: ids } },
      }),
      this.prisma.transaction.deleteMany({
        where: { id: { in: ids } },
      }),
    ]);

    return { deleted: ids.length };
  }

  // ─────────────────────── Private helper ───────────────────────

  private async findOneOwned(userId: string, id: string) {
    const tx = await this.prisma.transaction.findUnique({ where: { id } });
    if (!tx) throw new NotFoundException('거래 내역을 찾을 수 없습니다.');
    if (tx.userId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return tx;
  }
}

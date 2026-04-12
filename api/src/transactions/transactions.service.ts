import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { QueryTransactionDto } from './dto/query-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 목록 조회 ───────────────────────

  findAll(userId: string, query: QueryTransactionDto) {
    const where: {
      userId: string;
      type?: string;
      targetMonth?: string;
      date?: { gte: Date; lt: Date };
    } = { userId };

    if (query.type) {
      where.type = query.type;
    }

    if (query.month) {
      const [yyyy, mm] = query.month.split('-').map(Number);
      // targetMonth가 null인 수동 입력 거래도 함께 조회
      return this.prisma.transaction.findMany({
        where: {
          userId,
          ...(query.type ? { type: query.type } : {}),
          OR: [
            { targetMonth: query.month },
            {
              targetMonth: null,
              date: {
                gte: new Date(yyyy, mm - 1, 1),
                lt: new Date(yyyy, mm, 1),
              },
            },
          ],
        },
        orderBy: { date: 'desc' },
      });
    }

    return this.prisma.transaction.findMany({
      where,
      orderBy: { date: 'desc' },
    });
  }

  // ─────────────────────── 생성 ───────────────────────

  async create(userId: string, dto: CreateTransactionDto) {
    const transaction = await this.prisma.transaction.create({
      data: {
        userId,
        type: dto.type,
        name: dto.name,
        amount: dto.amount,
        date: new Date(dto.date),
        category: dto.category,
        subCategory: dto.subCategory,
        paymentMethod: dto.paymentMethod ?? null,
        targetMonth: dto.targetMonth ?? null,
        isInstallment: dto.isInstallment ?? false,
        installmentMonths: dto.installmentMonths ?? null,
        installmentRound: dto.installmentRound ?? null,
      },
    });

    // 그룹에 자동 공유
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
        ...(dto.type && { type: dto.type }),
        ...(dto.name && { name: dto.name }),
        ...(dto.amount !== undefined && { amount: dto.amount }),
        ...(dto.date && { date: new Date(dto.date) }),
        ...(dto.category && { category: dto.category }),
        ...(dto.subCategory && { subCategory: dto.subCategory }),
        ...(dto.paymentMethod !== undefined && { paymentMethod: dto.paymentMethod }),
        ...(dto.targetMonth !== undefined && { targetMonth: dto.targetMonth }),
        ...(dto.isInstallment !== undefined && { isInstallment: dto.isInstallment }),
        ...(dto.installmentMonths !== undefined && { installmentMonths: dto.installmentMonths }),
        ...(dto.installmentRound !== undefined && { installmentRound: dto.installmentRound }),
        editedByUserId: userId,
      },
    });
  }

  // ─────────────────────── 삭제 ───────────────────────

  async remove(userId: string, id: string) {
    await this.findOneOwned(userId, id);
    await this.prisma.transaction.delete({ where: { id } });
  }

  // ─────────────────────── Private helper ───────────────────────

  private async findOneOwned(userId: string, id: string) {
    const tx = await this.prisma.transaction.findUnique({ where: { id } });
    if (!tx) throw new NotFoundException('거래 내역을 찾을 수 없습니다.');
    if (tx.userId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return tx;
  }
}

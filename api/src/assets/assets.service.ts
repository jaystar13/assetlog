import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { UpsertHistoryDto } from './dto/upsert-history.dto';

@Injectable()
export class AssetsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 목록 조회 ───────────────────────

  findAll(userId: string, status?: string, month?: string) {
    return this.prisma.asset.findMany({
      where: {
        userId,
        ...(status ? { status } : { status: 'active' }),
      },
      include: {
        valueHistory: {
          where: month ? { month: { lte: month } } : undefined,
          orderBy: { month: 'desc' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ─────────────────────── 생성 ───────────────────────

  async create(userId: string, dto: CreateAssetDto) {
    const asset = await this.prisma.asset.create({
      data: {
        userId,
        categoryId: dto.categoryId,
        name: dto.name,
      },
    });

    // 그룹에 자동 공유
    if (dto.shareGroupIds?.length) {
      await this.prisma.sharedItem.createMany({
        data: dto.shareGroupIds.map((groupId) => ({
          groupId,
          ownerUserId: userId,
          itemType: 'asset',
          itemId: asset.id,
        })),
        skipDuplicates: true,
      });
    }

    return asset;
  }

  // ─────────────────────── 수정 ───────────────────────

  async update(userId: string, id: string, dto: UpdateAssetDto) {
    const asset = await this.findOneOwned(userId, id);

    return this.prisma.asset.update({
      where: { id: asset.id },
      data: {
        ...(dto.categoryId && { categoryId: dto.categoryId }),
        ...(dto.name && { name: dto.name }),
      },
    });
  }

  // ─────────────────────── 종료 (soft close) ───────────────────────

  async close(userId: string, id: string) {
    const asset = await this.findOneOwned(userId, id);

    return this.prisma.asset.update({
      where: { id: asset.id },
      data: { status: 'closed', closedAt: new Date() },
    });
  }

  // ─────────────────────── 삭제 ───────────────────────

  async remove(userId: string, id: string) {
    const asset = await this.findOneOwned(userId, id);
    await this.prisma.asset.delete({ where: { id: asset.id } });
  }

  // ─────────────────────── 히스토리 조회 ───────────────────────

  async findHistory(userId: string, assetId: string) {
    await this.findOneOwned(userId, assetId);
    return this.prisma.assetValueHistory.findMany({
      where: { assetId },
      orderBy: { month: 'desc' },
    });
  }

  // ─────────────────────── 히스토리 수동 기록 (B방식 upsert) ───────────────────────

  async upsertHistory(userId: string, assetId: string, month: string, dto: UpsertHistoryDto) {
    await this.findOneOwned(userId, assetId);

    return this.prisma.assetValueHistory.upsert({
      where: { assetId_month: { assetId, month } },
      create: { assetId, month, value: BigInt(dto.value) },
      update: { value: BigInt(dto.value) },
    });
  }

  // ─────────────────────── Private helpers ───────────────────────

  private async findOneOwned(userId: string, assetId: string) {
    const asset = await this.prisma.asset.findUnique({ where: { id: assetId } });
    if (!asset) throw new NotFoundException('자산을 찾을 수 없습니다.');
    if (asset.userId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return asset;
  }
}

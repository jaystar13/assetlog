import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAssetDto } from './dto/create-asset.dto';
import { UpdateAssetDto } from './dto/update-asset.dto';
import { UpsertHistoryDto } from './dto/upsert-history.dto';

@Injectable()
export class AssetsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 목록 조회 ───────────────────────

  findAll(userId: string) {
    return this.prisma.asset.findMany({
      where: { userId },
      include: { valueHistory: { orderBy: { month: 'desc' }, take: 2 } },
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
        currentValue: BigInt(dto.currentValue),
      },
    });

    // B방식: 생성 시 당월 히스토리 자동 기록
    await this.upsertCurrentMonthHistory(asset.id, dto.currentValue);

    return asset;
  }

  // ─────────────────────── 수정 ───────────────────────

  async update(userId: string, id: string, dto: UpdateAssetDto) {
    const asset = await this.findOneOwned(userId, id);

    const updated = await this.prisma.asset.update({
      where: { id: asset.id },
      data: {
        ...(dto.categoryId && { categoryId: dto.categoryId }),
        ...(dto.name && { name: dto.name }),
        ...(dto.currentValue !== undefined && { currentValue: BigInt(dto.currentValue) }),
        editedByUserId: userId,
      },
    });

    // B방식: 값이 변경된 경우 당월 히스토리 upsert
    if (dto.currentValue !== undefined) {
      await this.upsertCurrentMonthHistory(id, dto.currentValue);
    }

    return updated;
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

    const history = await this.prisma.assetValueHistory.upsert({
      where: { assetId_month: { assetId, month } },
      create: { assetId, month, value: BigInt(dto.value) },
      update: { value: BigInt(dto.value) },
    });

    // 당월인 경우 currentValue도 함께 업데이트
    const currentMonth = this.getCurrentMonth();
    if (month === currentMonth) {
      await this.prisma.asset.update({
        where: { id: assetId },
        data: { currentValue: BigInt(dto.value), editedByUserId: userId },
      });
    }

    return history;
  }

  // ─────────────────────── Private helpers ───────────────────────

  private async findOneOwned(userId: string, assetId: string) {
    const asset = await this.prisma.asset.findUnique({ where: { id: assetId } });
    if (!asset) throw new NotFoundException('자산을 찾을 수 없습니다.');
    if (asset.userId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return asset;
  }

  private getCurrentMonth(): string {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    return `${yyyy}-${mm}`;
  }

  private async upsertCurrentMonthHistory(assetId: string, value: number) {
    const month = this.getCurrentMonth();
    await this.prisma.assetValueHistory.upsert({
      where: { assetId_month: { assetId, month } },
      create: { assetId, month, value: BigInt(value) },
      update: { value: BigInt(value) },
    });
  }
}

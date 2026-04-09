import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdatePermissionsDto } from './dto/update-permissions.dto';

const USER_SELECT = { id: true, name: true, email: true, avatar: true };

@Injectable()
export class SharedAccessService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 내가 소유자인 공유 목록 ───────────────────────

  findOwned(userId: string) {
    return this.prisma.sharedAccess.findMany({
      where: { ownerUserId: userId },
      include: { sharedWith: { select: USER_SELECT } },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ─────────────────────── 나에게 공유된 목록 ───────────────────────

  findSharedWithMe(userId: string) {
    return this.prisma.sharedAccess.findMany({
      where: { sharedWithUserId: userId },
      include: { owner: { select: USER_SELECT } },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ─────────────────────── 권한 수정 (소유자만) ───────────────────────

  async updatePermissions(userId: string, id: string, dto: UpdatePermissionsDto) {
    const access = await this.findOwnedAccess(userId, id);

    return this.prisma.sharedAccess.update({
      where: { id: access.id },
      data: {
        ...(dto.cashflowPermission !== undefined && { cashflowPermission: dto.cashflowPermission }),
        ...(dto.assetPermissions !== undefined && { assetPermissions: dto.assetPermissions }),
      },
      include: { sharedWith: { select: USER_SELECT } },
    });
  }

  // ─────────────────────── 공유 해제 (소유자만) ───────────────────────

  async remove(userId: string, id: string) {
    const access = await this.findOwnedAccess(userId, id);
    await this.prisma.sharedAccess.delete({ where: { id: access.id } });
  }

  // ─────────────────────── 공유자의 자산 조회 (권한 기반) ───────────────────────

  async getSharedAssets(userId: string, accessId: string, month?: string) {
    const access = await this.findGrantedAccess(userId, accessId);
    const permissions = access.assetPermissions as Record<string, string>;

    // 권한이 있는 카테고리만 필터
    const allowedCategories = Object.entries(permissions)
      .filter(([_, level]) => level === 'view' || level === 'edit')
      .map(([catId]) => catId);

    if (allowedCategories.length === 0) return [];

    return this.prisma.asset.findMany({
      where: {
        userId: access.ownerUserId,
        status: 'active',
        categoryId: { in: allowedCategories },
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

  // ─────────────────────── 공유자의 거래 조회 (권한 기반) ───────────────────────

  async getSharedTransactions(userId: string, accessId: string, month?: string) {
    const access = await this.findGrantedAccess(userId, accessId);

    if (access.cashflowPermission === 'none') return [];

    const where: Record<string, unknown> = { userId: access.ownerUserId };

    if (month) {
      const [yyyy, mm] = month.split('-').map(Number);
      where.OR = [
        { targetMonth: month },
        {
          targetMonth: null,
          date: {
            gte: new Date(yyyy, mm - 1, 1),
            lt: new Date(yyyy, mm, 1),
          },
        },
      ];
    }

    return this.prisma.transaction.findMany({
      where,
      orderBy: { date: 'desc' },
    });
  }

  // ─────────────────────── Private helpers ───────────────────────

  /** 소유자로서 접근 가능한 SharedAccess 찾기 */
  private async findOwnedAccess(userId: string, accessId: string) {
    const access = await this.prisma.sharedAccess.findUnique({ where: { id: accessId } });
    if (!access) throw new NotFoundException('공유 정보를 찾을 수 없습니다.');
    if (access.ownerUserId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return access;
  }

  /** 공유 대상자로서 접근 가능한 SharedAccess 찾기 */
  private async findGrantedAccess(userId: string, accessId: string) {
    const access = await this.prisma.sharedAccess.findUnique({ where: { id: accessId } });
    if (!access) throw new NotFoundException('공유 정보를 찾을 수 없습니다.');
    if (access.sharedWithUserId !== userId) throw new ForbiddenException('접근 권한이 없습니다.');
    return access;
  }
}

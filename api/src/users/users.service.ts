import { Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpsertGoalDto } from './dto/upsert-goal.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByEmail(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (user?.deletedAt) return null;
    return user;
  }

  async update(id: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.avatar !== undefined && { avatar: dto.avatar }),
      },
    });
  }

  async withdraw(id: string, reason?: string) {
    const user = await this.findById(id);

    const purgeAfter = new Date();
    purgeAfter.setDate(purgeAfter.getDate() + 7);

    const emailHash = createHash('sha256').update(user.email.toLowerCase()).digest('hex');

    // 탈퇴 이력 기록
    await this.prisma.withdrawalLog.create({
      data: {
        emailHash,
        provider: user.provider,
        reason: reason ?? null,
        purgeAfter,
      },
    });

    // soft delete
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    // 리프레시 토큰 전부 삭제 (로그인 차단)
    await this.prisma.refreshToken.deleteMany({ where: { userId: id } });
  }

  async restoreAccount(id: string) {
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: null },
    });
  }

  // ─────────────────────── Financial Goal ───────────────────────

  async getGoal(userId: string) {
    return this.prisma.financialGoal.findUnique({
      where: { userId },
    });
  }

  async upsertGoal(userId: string, dto: UpsertGoalDto) {
    const data = {
      startAmount: BigInt(Math.round(dto.startAmount)),
      targetAmount: BigInt(Math.round(dto.targetAmount)),
      deadline: new Date(dto.deadline + 'T00:00:00.000Z'),
    };

    return this.prisma.financialGoal.upsert({
      where: { userId },
      create: { userId, ...data },
      update: data,
    });
  }
}

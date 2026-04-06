import { Injectable, NotFoundException } from '@nestjs/common';
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
    return this.prisma.user.findUnique({ where: { email } });
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

  async remove(id: string) {
    await this.prisma.user.delete({ where: { id } });
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

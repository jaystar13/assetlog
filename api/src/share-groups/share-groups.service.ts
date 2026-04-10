import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { InviteToGroupDto } from './dto/invite-to-group.dto';
import { ShareItemsDto } from './dto/share-items.dto';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto';

const USER_SELECT = { id: true, name: true, email: true, avatar: true };

@Injectable()
export class ShareGroupsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 그룹 CRUD ───────────────────────

  async create(userId: string, dto: CreateGroupDto) {
    return this.prisma.shareGroup.create({
      data: {
        name: dto.name,
        createdById: userId,
        members: {
          create: { userId, role: 'admin' },
        },
      },
      include: {
        members: { include: { user: { select: USER_SELECT } } },
      },
    });
  }

  findMyGroups(userId: string) {
    return this.prisma.shareGroup.findMany({
      where: { members: { some: { userId } } },
      include: {
        members: { include: { user: { select: USER_SELECT } } },
        _count: { select: { sharedItems: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    return this.prisma.shareGroup.findUnique({
      where: { id: groupId },
      include: {
        members: { include: { user: { select: USER_SELECT } } },
        _count: { select: { sharedItems: true } },
      },
    });
  }

  async update(userId: string, groupId: string, dto: CreateGroupDto) {
    await this.assertAdmin(userId, groupId);
    return this.prisma.shareGroup.update({
      where: { id: groupId },
      data: { name: dto.name },
    });
  }

  async remove(userId: string, groupId: string) {
    await this.assertAdmin(userId, groupId);
    await this.prisma.shareGroup.delete({ where: { id: groupId } });
  }

  // ─────────────────────── 멤버 관리 ───────────────────────

  async invite(userId: string, userEmail: string, groupId: string, dto: InviteToGroupDto) {
    await this.assertAdmin(userId, groupId);

    if (dto.toEmail.toLowerCase() === userEmail.toLowerCase()) {
      throw new BadRequestException('자기 자신에게는 초대를 보낼 수 없습니다.');
    }

    // 이미 멤버인지 확인
    const targetUser = await this.prisma.user.findUnique({
      where: { email: dto.toEmail.toLowerCase() },
    });
    if (targetUser) {
      const existing = await this.prisma.shareGroupMember.findUnique({
        where: { groupId_userId: { groupId, userId: targetUser.id } },
      });
      if (existing) throw new BadRequestException('이미 그룹 멤버입니다.');
    }

    // 중복 pending 초대 확인
    const pendingInvite = await this.prisma.groupInvitation.findFirst({
      where: { groupId, toEmail: dto.toEmail.toLowerCase(), status: 'pending' },
    });
    if (pendingInvite) throw new BadRequestException('이미 대기 중인 초대가 있습니다.');

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    return this.prisma.groupInvitation.create({
      data: {
        groupId,
        invitedById: userId,
        toEmail: dto.toEmail.toLowerCase(),
        role: dto.role ?? 'viewer',
        message: dto.message ?? null,
        expiresAt,
      },
      include: {
        group: { select: { id: true, name: true } },
        invitedBy: { select: USER_SELECT },
      },
    });
  }

  async updateMemberRole(userId: string, groupId: string, memberId: string, dto: UpdateMemberRoleDto) {
    await this.assertAdmin(userId, groupId);

    const member = await this.prisma.shareGroupMember.findUnique({ where: { id: memberId } });
    if (!member || member.groupId !== groupId) throw new NotFoundException('멤버를 찾을 수 없습니다.');

    return this.prisma.shareGroupMember.update({
      where: { id: memberId },
      data: { role: dto.role },
      include: { user: { select: USER_SELECT } },
    });
  }

  async removeMember(userId: string, groupId: string, memberId: string) {
    await this.assertAdmin(userId, groupId);

    const member = await this.prisma.shareGroupMember.findUnique({ where: { id: memberId } });
    if (!member || member.groupId !== groupId) throw new NotFoundException('멤버를 찾을 수 없습니다.');
    if (member.userId === userId) throw new BadRequestException('자기 자신은 제거할 수 없습니다.');

    // 해당 멤버가 공유한 항목도 함께 삭제
    await this.prisma.$transaction([
      this.prisma.sharedItem.deleteMany({ where: { groupId, ownerUserId: member.userId } }),
      this.prisma.shareGroupMember.delete({ where: { id: memberId } }),
    ]);
  }

  async leaveGroup(userId: string, groupId: string) {
    const member = await this.prisma.shareGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId } },
    });
    if (!member) throw new NotFoundException('그룹 멤버가 아닙니다.');
    if (member.role === 'admin') throw new BadRequestException('관리자는 그룹을 탈퇴할 수 없습니다. 그룹을 삭제하세요.');

    await this.prisma.$transaction([
      this.prisma.sharedItem.deleteMany({ where: { groupId, ownerUserId: userId } }),
      this.prisma.shareGroupMember.delete({ where: { id: member.id } }),
    ]);
  }

  // ─────────────────────── 초대 수신 ───────────────────────

  findReceivedInvitations(userEmail: string) {
    return this.prisma.groupInvitation.findMany({
      where: { toEmail: userEmail.toLowerCase() },
      include: {
        group: { select: { id: true, name: true } },
        invitedBy: { select: USER_SELECT },
      },
      orderBy: { sentAt: 'desc' },
    });
  }

  async acceptInvitation(userId: string, userEmail: string, invitationId: string) {
    const invitation = await this.prisma.groupInvitation.findUnique({ where: { id: invitationId } });
    if (!invitation) throw new NotFoundException('초대를 찾을 수 없습니다.');
    if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
      throw new ForbiddenException('본인에게 온 초대만 수락할 수 있습니다.');
    }
    if (invitation.status !== 'pending') {
      throw new BadRequestException('대기 중인 초대만 수락할 수 있습니다.');
    }
    if (new Date() > invitation.expiresAt) {
      await this.prisma.groupInvitation.update({ where: { id: invitationId }, data: { status: 'expired' } });
      throw new BadRequestException('만료된 초대입니다.');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.groupInvitation.update({ where: { id: invitationId }, data: { status: 'accepted' } });
      return tx.shareGroupMember.create({
        data: {
          groupId: invitation.groupId,
          userId,
          role: invitation.role,
        },
        include: {
          group: { select: { id: true, name: true } },
          user: { select: USER_SELECT },
        },
      });
    });
  }

  async declineInvitation(userEmail: string, invitationId: string) {
    const invitation = await this.prisma.groupInvitation.findUnique({ where: { id: invitationId } });
    if (!invitation) throw new NotFoundException('초대를 찾을 수 없습니다.');
    if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
      throw new ForbiddenException('본인에게 온 초대만 거절할 수 있습니다.');
    }
    if (invitation.status !== 'pending') {
      throw new BadRequestException('대기 중인 초대만 거절할 수 있습니다.');
    }

    return this.prisma.groupInvitation.update({
      where: { id: invitationId },
      data: { status: 'declined' },
    });
  }

  // ─────────────────────── 항목 공유 ───────────────────────

  async shareItems(userId: string, groupId: string, dto: ShareItemsDto) {
    await this.assertMember(userId, groupId);

    const data = dto.items.map((item) => ({
      groupId,
      ownerUserId: userId,
      itemType: item.itemType,
      itemId: item.itemId,
      permission: item.permission ?? 'view',
    }));

    // skipDuplicates로 이미 공유된 항목은 무시
    await this.prisma.sharedItem.createMany({ data, skipDuplicates: true });

    return { shared: data.length };
  }

  async unshareItem(userId: string, groupId: string, sharedItemId: string) {
    const item = await this.prisma.sharedItem.findUnique({ where: { id: sharedItemId } });
    if (!item || item.groupId !== groupId) throw new NotFoundException('공유 항목을 찾을 수 없습니다.');
    if (item.ownerUserId !== userId) {
      // admin은 다른 사람의 공유도 해제 가능
      await this.assertAdmin(userId, groupId);
    }

    await this.prisma.sharedItem.delete({ where: { id: sharedItemId } });
  }

  // ─────────────────────── 공유 데이터 조회 ───────────────────────

  async getGroupTransactions(userId: string, groupId: string, month?: string) {
    await this.assertMember(userId, groupId);

    const sharedItems = await this.prisma.sharedItem.findMany({
      where: { groupId, itemType: 'transaction' },
      select: { itemId: true, permission: true, ownerUserId: true },
    });

    if (sharedItems.length === 0) return [];

    const txIds = sharedItems.map((si) => si.itemId);

    const where: Record<string, unknown> = { id: { in: txIds } };
    if (month) {
      const [yyyy, mm] = month.split('-').map(Number);
      where.OR = [
        { targetMonth: month },
        { targetMonth: null, date: { gte: new Date(yyyy, mm - 1, 1), lt: new Date(yyyy, mm, 1) } },
      ];
    }

    const transactions = await this.prisma.transaction.findMany({
      where,
      include: { user: { select: USER_SELECT } },
      orderBy: { date: 'desc' },
    });

    return transactions.map((tx) => {
      const si = sharedItems.find((s) => s.itemId === tx.id);
      return { ...tx, _permission: si?.permission ?? 'view' };
    });
  }

  async getGroupAssets(userId: string, groupId: string, month?: string) {
    await this.assertMember(userId, groupId);

    const sharedItems = await this.prisma.sharedItem.findMany({
      where: { groupId, itemType: 'asset' },
      select: { itemId: true, permission: true, ownerUserId: true },
    });

    if (sharedItems.length === 0) return [];

    const assetIds = sharedItems.map((si) => si.itemId);

    return this.prisma.asset.findMany({
      where: { id: { in: assetIds }, status: 'active' },
      include: {
        user: { select: USER_SELECT },
        valueHistory: {
          where: month ? { month: { lte: month } } : undefined,
          orderBy: { month: 'desc' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // ─────────────────────── Private helpers ───────────────────────

  private async assertMember(userId: string, groupId: string) {
    const member = await this.prisma.shareGroupMember.findUnique({
      where: { groupId_userId: { groupId, userId } },
    });
    if (!member) throw new ForbiddenException('그룹 멤버가 아닙니다.');
    return member;
  }

  private async assertAdmin(userId: string, groupId: string) {
    const member = await this.assertMember(userId, groupId);
    if (member.role !== 'admin') throw new ForbiddenException('관리자 권한이 필요합니다.');
    return member;
  }
}

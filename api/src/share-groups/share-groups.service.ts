import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { INVITATION_EXPIRY_DAYS } from '../common/constants/app.constants';
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

    // 대상 사용자 확인
    const targetUser = await this.prisma.user.findUnique({
      where: { email: dto.toEmail.toLowerCase() },
    });
    if (targetUser) {
      // 탈퇴한 사용자 초대 차단
      if (targetUser.deletedAt) throw new BadRequestException('탈퇴한 사용자에게는 초대를 보낼 수 없습니다.');
      // 이미 멤버인지 확인
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
    expiresAt.setDate(expiresAt.getDate() + INVITATION_EXPIRY_DAYS);

    const invitation = await this.prisma.groupInvitation.create({
      data: {
        groupId,
        invitedById: userId,
        toEmail: dto.toEmail.toLowerCase(),
        role: 'viewer',
        nickname: dto.nickname ?? null,
        color: dto.color ?? null,
        message: dto.message ?? null,
        expiresAt,
      },
      include: {
        group: { select: { id: true, name: true } },
        invitedBy: { select: USER_SELECT },
      },
    });

    await this.logActivity({
      groupId,
      actorUserId: userId,
      action: 'invited',
      targetEmail: dto.toEmail.toLowerCase(),
      targetNickname: dto.nickname ?? null,
    });

    return invitation;
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

    const targetUser = await this.prisma.user.findUnique({ where: { id: member.userId }, select: { email: true } });

    await this.prisma.$transaction([
      this.prisma.sharedItem.deleteMany({ where: { groupId, ownerUserId: member.userId } }),
      this.prisma.shareGroupMember.delete({ where: { id: memberId } }),
    ]);

    await this.logActivity({
      groupId,
      actorUserId: userId,
      action: 'member_removed',
      targetEmail: targetUser?.email ?? null,
      targetNickname: member.nickname ?? null,
    });
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

    await this.logActivity({
      groupId,
      actorUserId: userId,
      action: 'member_left',
      targetNickname: member.nickname ?? null,
    });
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
    const result = await this.prisma.$transaction(async (tx) => {
      const invitation = await tx.groupInvitation.findUnique({ where: { id: invitationId } });
      if (!invitation) throw new NotFoundException('초대를 찾을 수 없습니다.');
      if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
        throw new ForbiddenException('본인에게 온 초대만 수락할 수 있습니다.');
      }
      if (invitation.status !== 'pending') {
        throw new BadRequestException('대기 중인 초대만 수락할 수 있습니다.');
      }
      if (new Date() > invitation.expiresAt) {
        await tx.groupInvitation.update({ where: { id: invitationId }, data: { status: 'expired' } });
        throw new BadRequestException('만료된 초대입니다.');
      }

      await tx.groupInvitation.update({ where: { id: invitationId }, data: { status: 'accepted' } });
      return tx.shareGroupMember.create({
        data: {
          groupId: invitation.groupId,
          userId,
          role: invitation.role,
          nickname: invitation.nickname,
          color: invitation.color,
        },
        include: {
          group: { select: { id: true, name: true } },
          user: { select: USER_SELECT },
        },
      });
    });

    await this.logActivity({
      groupId: result.group.id,
      actorUserId: userId,
      action: 'accepted',
      targetEmail: userEmail,
      targetNickname: result.nickname ?? null,
    });

    return result;
  }

  async declineInvitation(userId: string, userEmail: string, invitationId: string) {
    const invitation = await this.prisma.groupInvitation.findUnique({ where: { id: invitationId } });
    if (!invitation) throw new NotFoundException('초대를 찾을 수 없습니다.');
    if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
      throw new ForbiddenException('본인에게 온 초대만 거절할 수 있습니다.');
    }
    if (invitation.status !== 'pending') {
      throw new BadRequestException('대기 중인 초대만 거절할 수 있습니다.');
    }

    const result = await this.prisma.groupInvitation.update({
      where: { id: invitationId },
      data: { status: 'declined' },
    });

    await this.logActivity({
      groupId: invitation.groupId,
      actorUserId: userId,
      action: 'declined',
      targetEmail: userEmail,
      targetNickname: invitation.nickname ?? null,
    });

    return result;
  }

  // ─────────────────────── 항목 공유 ───────────────────────

  async shareItems(userId: string, groupId: string, dto: ShareItemsDto) {
    await this.assertMember(userId, groupId);

    // 아이템 소유권 검증
    const txIds = dto.items.filter((i) => i.itemType === 'transaction').map((i) => i.itemId);
    const assetIds = dto.items.filter((i) => i.itemType === 'asset').map((i) => i.itemId);

    if (txIds.length > 0) {
      const owned = await this.prisma.transaction.findMany({ where: { id: { in: txIds }, userId } });
      if (owned.length !== txIds.length) throw new ForbiddenException('본인의 거래만 공유할 수 있습니다.');
    }
    if (assetIds.length > 0) {
      const owned = await this.prisma.asset.findMany({ where: { id: { in: assetIds }, userId } });
      if (owned.length !== assetIds.length) throw new ForbiddenException('본인의 자산만 공유할 수 있습니다.');
    }

    const data = dto.items.map((item) => ({
      groupId,
      ownerUserId: userId,
      itemType: item.itemType,
      itemId: item.itemId,
    }));

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

  async getItemSharedGroups(userId: string, itemType: string, itemId: string) {
    const items = await this.prisma.sharedItem.findMany({
      where: { ownerUserId: userId, itemType, itemId },
      select: { groupId: true },
    });
    return items.map((i) => i.groupId);
  }

  async getGroupTransactions(userId: string, groupId: string, month?: string) {
    await this.assertMember(userId, groupId);

    const sharedItems = await this.prisma.sharedItem.findMany({
      where: { groupId, itemType: 'transaction' },
      select: { itemId: true, ownerUserId: true },
    });

    if (sharedItems.length === 0) return [];

    const txIds = sharedItems.map((si) => si.itemId);

    const where: Record<string, unknown> = { id: { in: txIds } };
    if (month) {
      where.targetMonth = month;
    }

    // 멤버 정보 (nickname, color) 조회
    const members = await this.prisma.shareGroupMember.findMany({
      where: { groupId },
      select: { userId: true, nickname: true, color: true },
    });
    const memberMap = new Map(members.map((m) => [m.userId, { nickname: m.nickname, color: m.color }]));

    const transactions = await this.prisma.transaction.findMany({
      where,
      include: { user: { select: USER_SELECT } },
      orderBy: [{ targetMonth: 'desc' }, { type: 'asc' }, { category: 'asc' }],
    });

    return transactions.map((tx) => {
      const memberInfo = memberMap.get(tx.userId);
      return { ...tx, _nickname: memberInfo?.nickname ?? null, _color: memberInfo?.color ?? null };
    });
  }

  async getGroupAssets(userId: string, groupId: string, month?: string) {
    await this.assertMember(userId, groupId);

    const sharedItems = await this.prisma.sharedItem.findMany({
      where: { groupId, itemType: 'asset' },
      select: { itemId: true, ownerUserId: true },
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

  // ─────────────────────── 활동 이력 ───────────────────────

  private async logActivity(params: {
    groupId: string;
    actorUserId: string;
    action: string;
    targetEmail?: string | null;
    targetNickname?: string | null;
    memo?: string | null;
  }) {
    await this.prisma.groupActivityLog.create({ data: params });
  }

  async findActivityLogs(userId: string, groupId: string) {
    await this.assertMember(userId, groupId);
    return this.prisma.groupActivityLog.findMany({
      where: { groupId },
      include: { actor: { select: USER_SELECT } },
      orderBy: { createdAt: 'desc' },
    });
  }
}

import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';

@Injectable()
export class InvitationsService {
  constructor(private prisma: PrismaService) {}

  // ─────────────────────── 초대 생성 ───────────────────────

  async create(userId: string, userEmail: string, dto: CreateInvitationDto) {
    // 자기 자신에게 초대 금지
    if (dto.toEmail.toLowerCase() === userEmail.toLowerCase()) {
      throw new BadRequestException('자기 자신에게는 초대를 보낼 수 없습니다.');
    }

    // 같은 이메일에 pending 초대가 이미 있는지 확인
    const existing = await this.prisma.invitation.findFirst({
      where: {
        fromUserId: userId,
        toEmail: dto.toEmail.toLowerCase(),
        status: 'pending',
      },
    });
    if (existing) {
      throw new BadRequestException('이미 해당 이메일로 대기 중인 초대가 있습니다.');
    }

    // 이미 공유 중인지 확인
    const targetUser = await this.prisma.user.findUnique({
      where: { email: dto.toEmail.toLowerCase() },
    });
    if (targetUser) {
      const existingAccess = await this.prisma.sharedAccess.findUnique({
        where: {
          ownerUserId_sharedWithUserId: {
            ownerUserId: userId,
            sharedWithUserId: targetUser.id,
          },
        },
      });
      if (existingAccess) {
        throw new BadRequestException('이미 해당 사용자와 공유 중입니다.');
      }
    }

    // 7일 후 만료
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    return this.prisma.invitation.create({
      data: {
        fromUserId: userId,
        toEmail: dto.toEmail.toLowerCase(),
        cashflowPermission: dto.cashflowPermission,
        assetPermissions: dto.assetPermissions,
        message: dto.message ?? null,
        expiresAt,
      },
      include: { fromUser: { select: { id: true, name: true, email: true, avatar: true } } },
    });
  }

  // ─────────────────────── 보낸 초대 목록 ───────────────────────

  findSent(userId: string) {
    return this.prisma.invitation.findMany({
      where: { fromUserId: userId },
      include: { fromUser: { select: { id: true, name: true, email: true, avatar: true } } },
      orderBy: { sentAt: 'desc' },
    });
  }

  // ─────────────────────── 받은 초대 목록 ───────────────────────

  findReceived(userEmail: string) {
    return this.prisma.invitation.findMany({
      where: { toEmail: userEmail.toLowerCase() },
      include: { fromUser: { select: { id: true, name: true, email: true, avatar: true } } },
      orderBy: { sentAt: 'desc' },
    });
  }

  // ─────────────────────── 초대 수락 ───────────────────────

  async accept(userId: string, userEmail: string, invitationId: string) {
    const invitation = await this.findValidInvitation(invitationId);

    // 수신자 본인 확인
    if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
      throw new ForbiddenException('본인에게 온 초대만 수락할 수 있습니다.');
    }

    // 상태 확인
    if (invitation.status !== 'pending') {
      throw new BadRequestException(`이미 ${invitation.status === 'accepted' ? '수락' : invitation.status === 'declined' ? '거절' : '만료'}된 초대입니다.`);
    }

    // 만료 확인
    if (new Date() > invitation.expiresAt) {
      await this.prisma.invitation.update({
        where: { id: invitationId },
        data: { status: 'expired' },
      });
      throw new BadRequestException('만료된 초대입니다.');
    }

    // 트랜잭션: 초대 수락 + SharedAccess 생성
    return this.prisma.$transaction(async (tx) => {
      await tx.invitation.update({
        where: { id: invitationId },
        data: { status: 'accepted' },
      });

      return tx.sharedAccess.create({
        data: {
          ownerUserId: invitation.fromUserId,
          sharedWithUserId: userId,
          cashflowPermission: invitation.cashflowPermission,
          assetPermissions: invitation.assetPermissions as object,
        },
        include: {
          owner: { select: { id: true, name: true, email: true, avatar: true } },
          sharedWith: { select: { id: true, name: true, email: true, avatar: true } },
        },
      });
    });
  }

  // ─────────────────────── 초대 거절 ───────────────────────

  async decline(userEmail: string, invitationId: string) {
    const invitation = await this.findValidInvitation(invitationId);

    if (invitation.toEmail.toLowerCase() !== userEmail.toLowerCase()) {
      throw new ForbiddenException('본인에게 온 초대만 거절할 수 있습니다.');
    }

    if (invitation.status !== 'pending') {
      throw new BadRequestException('대기 중인 초대만 거절할 수 있습니다.');
    }

    return this.prisma.invitation.update({
      where: { id: invitationId },
      data: { status: 'declined' },
    });
  }

  // ─────────────────────── 초대 취소 (발신자) ───────────────────────

  async cancel(userId: string, invitationId: string) {
    const invitation = await this.findValidInvitation(invitationId);

    if (invitation.fromUserId !== userId) {
      throw new ForbiddenException('본인이 보낸 초대만 취소할 수 있습니다.');
    }

    return this.prisma.invitation.delete({
      where: { id: invitationId },
    });
  }

  // ─────────────────────── Private helpers ───────────────────────

  private async findValidInvitation(id: string) {
    const invitation = await this.prisma.invitation.findUnique({ where: { id } });
    if (!invitation) throw new NotFoundException('초대를 찾을 수 없습니다.');
    return invitation;
  }
}

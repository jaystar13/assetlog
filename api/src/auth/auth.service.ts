import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { WITHDRAWAL_GRACE_DAYS } from '../common/constants/app.constants';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from './strategies/jwt.strategy';
import { JwtRefreshPayload } from './strategies/jwt-refresh.strategy';

export interface FindOrCreateUserDto {
  provider: string;
  providerId: string;
  email: string;
  name: string;
  avatar?: string;
}

@Injectable()
export class AuthService {
  // 일회용 인증 코드 저장소 (메모리)
  private authCodes = new Map<string, { userId: string; email: string; expiresAt: number; restored?: boolean; withdrawn?: boolean }>();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ───────────────────────────── Auth Code ─────────────────────────────

  createAuthCode(params: { userId: string; email: string; restored?: boolean; withdrawn?: boolean }): string {
    const code = randomUUID();
    this.authCodes.set(code, {
      ...params,
      expiresAt: Date.now() + 60 * 1000, // 1분 만료
    });
    return code;
  }

  async exchangeAuthCode(code: string) {
    const entry = this.authCodes.get(code);
    if (!entry) throw new BadRequestException('유효하지 않은 인증 코드입니다.');

    // 즉시 삭제 (1회 사용)
    this.authCodes.delete(code);

    if (entry.expiresAt < Date.now()) throw new BadRequestException('만료된 인증 코드입니다.');
    if (entry.withdrawn) throw new BadRequestException('탈퇴 처리된 계정입니다.');

    const tokens = await this.issueTokens(entry.userId, entry.email);
    return { ...tokens, restored: entry.restored ?? false };
  }

  // ───────────────────────────── findOrCreate ─────────────────────────────

  async findOrCreateUser(dto: FindOrCreateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { provider_providerId: { provider: dto.provider, providerId: dto.providerId } },
    });
    if (existing) {
      // 탈퇴 유예 기간 중 재로그인 → 자동 복구
      if (existing.deletedAt) {
        const daysSinceDelete = (Date.now() - existing.deletedAt.getTime()) / (1000 * 60 * 60 * 24);
        if (daysSinceDelete <= WITHDRAWAL_GRACE_DAYS) {
          await this.prisma.user.update({
            where: { id: existing.id },
            data: { deletedAt: null },
          });
          return { ...existing, deletedAt: null, _restored: true };
        }
        // 7일 초과 → 재가입 불가
        return { ...existing, _withdrawn: true };
      }
      return existing;
    }

    return this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        name: dto.name,
        avatar: dto.avatar ?? null,
        provider: dto.provider,
        providerId: dto.providerId,
      },
    });
  }

  // ───────────────────────────── token issuance ─────────────────────────────

  async issueTokens(userId: string, email: string, tx?: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0]) {
    const db = tx ?? this.prisma;
    const payload: JwtPayload = { sub: userId, email };

    const accessToken = this.jwtService.sign(payload as unknown as Record<string, unknown>, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: (this.configService.get<string>('JWT_EXPIRATION') ?? '15m') as never,
    });

    const rawRefresh = this.jwtService.sign(
      { sub: userId } as unknown as Record<string, unknown>,
      {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: (this.configService.get<string>('JWT_REFRESH_EXPIRATION') ?? '7d') as never,
      },
    );

    const hash = await bcrypt.hash(rawRefresh, 10);
    const expiresAt = new Date(Date.now() + this.parseExpirationToMs(
      this.configService.get<string>('JWT_REFRESH_EXPIRATION') ?? '7d',
    ));

    await db.refreshToken.create({
      data: { userId, token: hash, expiresAt },
    });

    return { accessToken, refreshToken: rawRefresh };
  }

  // ───────────────────────────── refresh ─────────────────────────────

  async refresh(payload: JwtRefreshPayload & { rawRefreshToken: string }) {
    const tokens = await this.prisma.refreshToken.findMany({
      where: { userId: payload.sub, expiresAt: { gt: new Date() } },
    });

    let matched: (typeof tokens)[0] | null = null;
    for (const t of tokens) {
      if (await bcrypt.compare(payload.rawRefreshToken, t.token)) {
        matched = t;
        break;
      }
    }

    if (!matched) throw new UnauthorizedException('Invalid refresh token');

    // Rotation: 트랜잭션으로 기존 토큰 삭제 + 새 토큰 발급 (원자적 처리)
    return this.prisma.$transaction(async (tx) => {
      await tx.refreshToken.delete({ where: { id: matched!.id } });
      return this.issueTokens(payload.sub, payload.email, tx);
    });
  }

  // ───────────────────────────── logout ─────────────────────────────

  async logout(userId: string, rawRefreshToken: string) {
    const tokens = await this.prisma.refreshToken.findMany({
      where: { userId },
    });

    for (const t of tokens) {
      if (await bcrypt.compare(rawRefreshToken, t.token)) {
        await this.prisma.refreshToken.delete({ where: { id: t.id } });
        return;
      }
    }
  }

  // 만료된 토큰 정리 (cron 용으로 추후 사용 가능)
  async cleanExpiredTokens() {
    await this.prisma.refreshToken.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });
  }

  /** '7d', '24h', '30m', '2w' 등 문자열을 밀리초로 변환 */
  private parseExpirationToMs(str: string): number {
    const match = str.match(/^(\d+)(s|m|h|d|w)$/);
    if (!match) return 7 * 24 * 60 * 60 * 1000; // fallback 7일
    const value = parseInt(match[1]);
    switch (match[2]) {
      case 's': return value * 1000;
      case 'm': return value * 60 * 1000;
      case 'h': return value * 60 * 60 * 1000;
      case 'd': return value * 24 * 60 * 60 * 1000;
      case 'w': return value * 7 * 24 * 60 * 60 * 1000;
      default: return 7 * 24 * 60 * 60 * 1000;
    }
  }
}

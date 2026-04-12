import { Injectable, UnauthorizedException } from '@nestjs/common';
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
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  // ───────────────────────────── findOrCreate ─────────────────────────────

  async findOrCreateUser(dto: FindOrCreateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { provider_providerId: { provider: dto.provider, providerId: dto.providerId } },
    });
    if (existing) {
      // 탈퇴 유예 기간 중 재로그인 → 자동 복구
      if (existing.deletedAt) {
        const daysSinceDelete = (Date.now() - existing.deletedAt.getTime()) / (1000 * 60 * 60 * 24);
        if (daysSinceDelete <= 7) {
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
        email: dto.email,
        name: dto.name,
        avatar: dto.avatar ?? null,
        provider: dto.provider,
        providerId: dto.providerId,
      },
    });
  }

  // ───────────────────────────── token issuance ─────────────────────────────

  async issueTokens(userId: string, email: string) {
    const payload: JwtPayload = { sub: userId, email };

    const accessToken = this.jwtService.sign(payload as unknown as Record<string, unknown>, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: (this.configService.get<string>('JWT_EXPIRATION') ?? '15m') as never,
    });

    // Refresh token: DB에 hash 저장 후 raw 반환
    const rawRefresh = this.jwtService.sign(
      { sub: userId } as unknown as Record<string, unknown>,
      {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: (this.configService.get<string>('JWT_REFRESH_EXPIRATION') ?? '7d') as never,
      },
    );

    const hash = await bcrypt.hash(rawRefresh, 10);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7일

    await this.prisma.refreshToken.create({
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

    // Rotation: 트랜잭션으로 기존 토큰 삭제 + 새 토큰 발급
    try {
      await this.prisma.refreshToken.delete({ where: { id: matched.id } });
      return await this.issueTokens(payload.sub, payload.email);
    } catch (e) {
      // 새 토큰 발급 실패 시에도 기존 토큰은 삭제됨 → 재로그인 필요
      throw new UnauthorizedException('토큰 갱신 실패, 다시 로그인해 주세요.');
    }
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
}

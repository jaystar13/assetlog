import {
  Controller,
  Get,
  Post,
  Req,
  Res,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import {
  ApiTags,
  ApiOperation,
  ApiBody,
  ApiBearerAuth,
  ApiResponse,
} from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import type { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { TokenResponseDto, RefreshRequestDto } from './dto/token-response.dto';
import { JwtRefreshPayload } from './strategies/jwt-refresh.strategy';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private configService: ConfigService,
  ) {}

  // ─────────────────────── Google OAuth ───────────────────────

  @Public()
  @Get('google')
  @UseGuards(AuthGuard('google'))
  @ApiOperation({ summary: 'Google OAuth 시작' })
  googleAuth() {
    // passport가 Google로 리다이렉트 처리
  }

  @Public()
  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  @ApiOperation({ summary: 'Google OAuth 콜백 → 딥링크로 토큰 전달' })
  async googleCallback(@Req() req: Request, @Res() res: Response) {
    return this.handleOAuthCallback(req, res);
  }

  // ─────────────────────── Kakao OAuth ───────────────────────

  @Public()
  @Get('kakao')
  @UseGuards(AuthGuard('kakao'))
  @ApiOperation({ summary: 'Kakao OAuth 시작' })
  kakaoAuth() {
    // passport가 Kakao로 리다이렉트 처리
  }

  @Public()
  @Get('kakao/callback')
  @UseGuards(AuthGuard('kakao'))
  @ApiOperation({ summary: 'Kakao OAuth 콜백 → 딥링크로 토큰 전달' })
  async kakaoCallback(@Req() req: Request, @Res() res: Response) {
    return this.handleOAuthCallback(req, res);
  }

  // ─────────────────────── Naver OAuth ───────────────────────

  @Public()
  @Get('naver')
  @UseGuards(AuthGuard('naver'))
  @ApiOperation({ summary: 'Naver OAuth 시작' })
  naverAuth() {
    // passport가 Naver로 리다이렉트 처리
  }

  @Public()
  @Get('naver/callback')
  @UseGuards(AuthGuard('naver'))
  @ApiOperation({ summary: 'Naver OAuth 콜백 → 딥링크로 토큰 전달' })
  async naverCallback(@Req() req: Request, @Res() res: Response) {
    return this.handleOAuthCallback(req, res);
  }

  // ─────────────────────── Token Refresh ───────────────────────

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AuthGuard('jwt-refresh'))
  @ApiOperation({ summary: 'Access Token 갱신 (Refresh Token Rotation)' })
  @ApiBody({ type: RefreshRequestDto })
  @ApiResponse({ status: 200, type: TokenResponseDto })
  async refresh(@CurrentUser() user: JwtRefreshPayload & { rawRefreshToken: string }) {
    return this.authService.refresh(user);
  }

  // ─────────────────────── Logout ───────────────────────

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: '로그아웃 (Refresh Token 삭제)' })
  @ApiBody({ type: RefreshRequestDto })
  async logout(
    @CurrentUser('id') userId: string,
    @Body() body: RefreshRequestDto,
  ) {
    await this.authService.logout(userId, body.refreshToken);
  }

  // ─────────────────────── Me ───────────────────────

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: '내 프로필 조회' })
  getMe(@CurrentUser() user: Record<string, unknown>) {
    const { id, email, name, avatar, provider, createdAt } = user as {
      id: string;
      email: string;
      name: string;
      avatar: string | null;
      provider: string;
      createdAt: Date;
    };
    return { id, email, name, avatar, provider, createdAt };
  }

  // ─────────────────────── Private helper ───────────────────────

  private async handleOAuthCallback(req: Request, res: Response) {
    const user = req.user as { id: string; email: string; _restored?: boolean; _withdrawn?: boolean };
    const deepLink = this.configService.get<string>('APP_DEEP_LINK')!;

    // 탈퇴 후 7일 초과 → 재가입 불가 안내
    if (user._withdrawn) {
      res.redirect(`${deepLink}?error=withdrawn`);
      return;
    }

    const tokens = await this.authService.issueTokens(user.id, user.email);
    let redirectUrl = `${deepLink}?access_token=${tokens.accessToken}&refresh_token=${tokens.refreshToken}`;
    if (user._restored) {
      redirectUrl += '&restored=true';
    }
    res.redirect(redirectUrl);
  }
}

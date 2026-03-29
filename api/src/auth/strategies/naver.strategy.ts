import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { AuthService } from '../auth.service';
// passport-naver-v2 has no @types — use require
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { Strategy } = require('passport-naver-v2') as { Strategy: new (...args: unknown[]) => unknown };

interface NaverProfile {
  id: string;
  email?: string;
  name?: string;
  profileImage?: string;
}

@Injectable()
export class NaverStrategy extends PassportStrategy(Strategy, 'naver') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      clientID: configService.get<string>('NAVER_CLIENT_ID') || 'NAVER_CLIENT_ID_PLACEHOLDER',
      clientSecret: configService.get<string>('NAVER_CLIENT_SECRET') || 'NAVER_CLIENT_SECRET_PLACEHOLDER',
      callbackURL: configService.get<string>('NAVER_CALLBACK_URL') || 'http://localhost:3000/auth/naver/callback',
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: NaverProfile,
    done: (error: Error | null, user?: unknown) => void,
  ) {
    const email = profile.email ?? `${profile.id}@naver.local`;
    const name = profile.name ?? '네이버 사용자';

    const user = await this.authService.findOrCreateUser({
      provider: 'naver',
      providerId: String(profile.id),
      email,
      name,
      avatar: profile.profileImage,
    });
    done(null, user);
  }
}

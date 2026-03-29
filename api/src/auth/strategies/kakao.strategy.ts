import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { Strategy } = require('passport-kakao') as { Strategy: new (...args: unknown[]) => unknown };
import { AuthService } from '../auth.service';

interface KakaoProfile {
  id: string | number;
  _json?: {
    kakao_account?: {
      email?: string;
      profile?: {
        nickname?: string;
        profile_image_url?: string;
      };
    };
  };
}

@Injectable()
export class KakaoStrategy extends PassportStrategy(Strategy, 'kakao') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      clientID: configService.get<string>('KAKAO_CLIENT_ID') || 'KAKAO_CLIENT_ID_PLACEHOLDER',
      clientSecret: configService.get<string>('KAKAO_CLIENT_SECRET') || '',
      callbackURL: configService.get<string>('KAKAO_CALLBACK_URL') || 'http://localhost:3000/auth/kakao/callback',
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: KakaoProfile,
    done: (error: Error | null, user?: unknown) => void,
  ) {
    const kakaoAccount = profile._json?.kakao_account;
    const email = kakaoAccount?.email ?? `${profile.id}@kakao.local`;
    const name = kakaoAccount?.profile?.nickname ?? '카카오 사용자';
    const avatar = kakaoAccount?.profile?.profile_image_url;

    const user = await this.authService.findOrCreateUser({
      provider: 'kakao',
      providerId: String(profile.id),
      email,
      name,
      avatar,
    });
    done(null, user);
  }
}

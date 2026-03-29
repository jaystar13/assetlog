import { ApiProperty } from '@nestjs/swagger';

export class TokenResponseDto {
  @ApiProperty({ description: 'JWT 액세스 토큰 (15분)' })
  accessToken: string;

  @ApiProperty({ description: 'JWT 리프레시 토큰 (7일)' })
  refreshToken: string;
}

export class RefreshRequestDto {
  @ApiProperty({ description: '리프레시 토큰' })
  refreshToken: string;
}

# ──────────────────────────────────────────────────────────
# AssetLog API - Production Dockerfile (Railway)
# Node 20.19 (Prisma 7 / NestJS 11 요구 충족, 로컬과 일치)
# Debian slim (glibc) — Prisma 기본 바이너리 호환
# ──────────────────────────────────────────────────────────

FROM node:20.19-slim

WORKDIR /app

# Prisma 가 OpenSSL 을 사용함. ca-certificates 는 TLS 연결(Neon) 용.
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 의존성 설치 단계 (캐시 최적화)
# postinstall 에서 prisma generate 가 실행되므로 schema 도 먼저 복사
COPY package.json package-lock.json ./
COPY prisma ./prisma

RUN npm ci

# 소스 코드 복사 및 빌드
COPY . .
RUN npm run build

# Railway 가 PORT 환경변수를 자동 주입
EXPOSE 3000

# preDeployCommand (prisma migrate deploy) 가 prisma CLI 를 사용하므로
# devDependencies 를 prune 하지 않음

CMD ["node", "dist/src/main.js"]

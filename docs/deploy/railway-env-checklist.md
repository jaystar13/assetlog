# Railway 배포 환경 변수 체크리스트

AssetLog API를 Railway Hobby 플랜에 배포할 때 등록해야 하는 환경 변수 및 설정 가이드입니다.

> 로컬에서 운영 환경 검증: `api/.env.production` + `npm run migrate:prod` / `npm run start:prod:local`
> Railway 배포: 아래 변수를 **Railway Console > Project > Service > Variables**에 등록. `.env.production` 파일은 업로드되지 않습니다 (gitignore로 차단).

---

## 사전 준비

### Railway Console에서 설정할 것
1. **GitHub 연동** → `assetlog` 저장소 선택
2. **Service Settings**
   - **Root Directory**: `/api` (모노레포이므로 반드시 지정)
   - **Build**: Nixpacks 자동 감지 (기본값 OK)
   - **Start Command**: `npm run start:prod` (railway.json 에 이미 지정됨)
   - **Pre-Deploy Command**: `npx prisma migrate deploy` (railway.json 에 이미 지정됨)
   - **Healthcheck Path**: `/health` (railway.json 에 이미 지정됨)

> `api/railway.json` 을 통해 3종 명령이 코드로 관리되므로 Console에서 별도 입력 불필요. 다만 **Root Directory는 Console에서 직접 설정**해야 합니다.

---

## 환경 변수

### Variable Type 가이드
- **Variable**: 평문, 로그/UI에 그대로 보임 (도메인, 만료시간 등)
- **Secret**: 암호화 보관, UI에서 마스킹 (비밀번호, 토큰, 키)

### Database (Neon)

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `DATABASE_URL` | **Secret** | Neon Console > Connect (Pooled) | 끝에 `&pgbouncer=true&connection_limit=1` 포함 |
| `DIRECT_URL` | **Secret** | Neon Console > Connect (Direct, `-pooler` 없음) | Pre-Deploy의 `prisma migrate deploy`가 사용 |

### App / Runtime

| Key | Type | 값 | 비고 |
|---|---|---|---|
| `NODE_ENV` | Variable | `production` | |
| `PORT` | ❌ 등록 금지 | — | Railway가 자동 주입 |
| `CORS_ORIGINS` | Variable | (빈 값 OK) | 모바일 앱만 사용 중이므로 필수 아님. 추후 웹 클라이언트 생기면 도메인 콤마 구분 |

### JWT

| Key | Type | 값 | 비고 |
|---|---|---|---|
| `JWT_SECRET` | **Secret** | `openssl rand -base64 48` 로 신규 생성 | 운영용으로 rotate 권장 |
| `JWT_REFRESH_SECRET` | **Secret** | 위와 동일, **JWT_SECRET과 다른 값** | |
| `JWT_EXPIRATION` | Variable | `15m` | |
| `JWT_REFRESH_EXPIRATION` | Variable | `7d` | |

### OAuth - Google

| Key | Type | 비고 |
|---|---|---|
| `GOOGLE_CLIENT_ID` | Variable | Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | **Secret** | |
| `GOOGLE_CALLBACK_URL` | Variable | `https://<railway-도메인>/auth/google/callback` — **Google Console에 redirect URI 등록 필요** |

### OAuth - Kakao

| Key | Type | 비고 |
|---|---|---|
| `KAKAO_CLIENT_ID` | Variable | Kakao Developers |
| `KAKAO_CLIENT_SECRET` | **Secret** | |
| `KAKAO_CALLBACK_URL` | Variable | `https://<railway-도메인>/auth/kakao/callback` — **Kakao Developers에 redirect URI 등록 필요** |

### OAuth - Naver

| Key | Type | 비고 |
|---|---|---|
| `NAVER_CLIENT_ID` | Variable | Naver Developers |
| `NAVER_CLIENT_SECRET` | **Secret** | |
| `NAVER_CALLBACK_URL` | Variable | `https://<railway-도메인>/auth/naver/callback` — **Naver Developers에 redirect URI 등록 필요** |

### App

| Key | Type | 값 | 비고 |
|---|---|---|---|
| `APP_DEEP_LINK` | Variable | `assetlog://auth/callback` | 모바일 앱 딥링크 스킴 |
| `MAX_UPLOAD_SIZE_MB` | Variable | `5` | Railway는 body 크기 제한 없음. 앱 레벨 제한 |

---

## 배포 전 체크리스트

- [ ] Railway 프로젝트 생성 및 GitHub 연동 완료
- [ ] Root Directory = `/api` 설정
- [ ] Neon Pooled / Direct connection string 확보 및 등록
- [ ] 운영용 JWT_SECRET / JWT_REFRESH_SECRET 신규 생성 후 등록 (`openssl rand -base64 48` x 2)
- [ ] Railway가 발급한 도메인(`<service>.up.railway.app`) 확인
- [ ] Google/Kakao/Naver 콘솔에 운영 redirect URI 등록
- [ ] Flutter 앱의 API base URL을 Railway 운영 도메인으로 교체

## 첫 배포 후 확인

- [ ] Railway Deploy 로그에서 `postinstall` → `prisma generate` 성공 확인
- [ ] `preDeployCommand` 로그에서 `prisma migrate deploy` 완료 확인 (첫 배포 시에도 이미 적용된 상태라 No pending 로그 예상)
- [ ] 기동 로그에 `🚀 AssetLog API running on http://localhost:$PORT` 출력 확인
- [ ] Railway Healthcheck 통과 상태 (Settings > Deployments)
- [ ] 외부에서 `curl https://<railway-도메인>/health` → HTTP 200 + `db: up` 응답

## 후속 배포 흐름

```
git push origin main
  → Railway 자동 감지
  → postinstall: prisma generate
  → build: nest build
  → preDeploy: prisma migrate deploy (새 마이그레이션 있으면 적용)
  → start: node dist/src/main
  → healthcheck: GET /health (통과 시 트래픽 전환)
```

Pre-Deploy 단계가 실패하면 새 버전은 기동되지 않고 이전 버전이 유지됩니다 (안전).

## 운영 팁

### 로그 확인
- Railway Console > Service > **Deployments** 탭 → 각 배포의 Build/Deploy Log
- 실시간 런타임 로그는 **Observability** 탭

### 환경 변수 변경 시
- Variables 수정 후 서비스 자동 재배포
- 재배포 중에도 이전 인스턴스가 응답 (Hobby는 단일 인스턴스라 순간 끊김 있을 수 있음)

### 롤백
- Deployments 탭에서 과거 성공 배포의 `⋯` → **Redeploy**
- 단, DB 마이그레이션을 되돌려야 하는 경우엔 별도 롤백 마이그레이션 필요 (Prisma는 자동 롤백 지원 안 함)

### 비용 모니터링
- Railway Console > **Usage** 탭에서 실시간 확인
- Hobby 플랜: $5 크레딧 포함, 초과분은 사용량 과금

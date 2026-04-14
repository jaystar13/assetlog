# Koyeb 배포 환경 변수 체크리스트

AssetLog API를 Koyeb에 배포할 때 등록해야 하는 환경 변수 목록입니다.
**Koyeb Console > Service > Settings > Environment variables** 에 등록합니다.

> 로컬에서 운영 환경 검증은 `api/.env.production` 파일 + `npm run migrate:prod` / `npm run start:prod:local` 로 수행합니다.
> Koyeb 배포 시에는 아래 변수들을 Koyeb의 Secret 또는 Plain 변수로 직접 등록하며, `.env.production` 파일은 업로드하지 않습니다.

---

## 등록 가이드

| Type | 사용 시점 | 비고 |
|---|---|---|
| **Secret** | 비밀번호·토큰·키 같은 민감 정보 | Koyeb이 암호화 보관, 로그에 마스킹 |
| **Plain** | 도메인 URL, 만료 시간 등 비민감 설정 | 그대로 노출 |

---

## 변수 목록

### Database (Neon)

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `DATABASE_URL` | **Secret** | Neon Console > Connect (Pooled) | 끝에 `&pgbouncer=true&connection_limit=1` 추가 권장 |
| `DIRECT_URL` | **Secret** | Neon Console > Connect (Direct, `-pooler` 없음) | Prisma migrate 전용 |

### JWT

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `JWT_SECRET` | **Secret** | 직접 생성 | 운영용으로 신규 생성 권장 (예: `openssl rand -base64 48`) |
| `JWT_REFRESH_SECRET` | **Secret** | 직접 생성 | 위와 동일, **JWT_SECRET과 다른 값** |
| `JWT_EXPIRATION` | Plain | `15m` | 필요시 조정 |
| `JWT_REFRESH_EXPIRATION` | Plain | `7d` | 필요시 조정 |

### OAuth - Google

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `GOOGLE_CLIENT_ID` | Plain | Google Cloud Console | dev와 동일 client 사용 가능 |
| `GOOGLE_CLIENT_SECRET` | **Secret** | Google Cloud Console | |
| `GOOGLE_CALLBACK_URL` | Plain | `https://<koyeb-도메인>/auth/google/callback` | **Google Console에 redirect URI 등록 필요** |

### OAuth - Kakao

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `KAKAO_CLIENT_ID` | Plain | Kakao Developers | |
| `KAKAO_CLIENT_SECRET` | **Secret** | Kakao Developers | |
| `KAKAO_CALLBACK_URL` | Plain | `https://<koyeb-도메인>/auth/kakao/callback` | **Kakao Developers에 redirect URI 등록 필요** |

### OAuth - Naver

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `NAVER_CLIENT_ID` | Plain | Naver Developers | |
| `NAVER_CLIENT_SECRET` | **Secret** | Naver Developers | |
| `NAVER_CALLBACK_URL` | Plain | `https://<koyeb-도메인>/auth/naver/callback` | **Naver Developers에 redirect URI 등록 필요** |

### App

| Key | Type | 값 출처 | 비고 |
|---|---|---|---|
| `APP_DEEP_LINK` | Plain | `assetlog://auth/callback` | 모바일 앱 딥링크 스킴 |
| `MAX_UPLOAD_SIZE_MB` | Plain | `5` | 파일 업로드 최대 크기 |
| `NODE_ENV` | Plain | `production` | Koyeb 빌드 시 자동 설정될 수도 있으나 명시 권장 |
| `PORT` | Plain | Koyeb이 자동 주입 | 직접 등록 불필요 (NestJS는 `process.env.PORT` 사용) |

---

## 배포 전 사전 작업 체크리스트

- [ ] Neon에서 Pooled / Direct connection string 확보 완료
- [ ] 운영용 JWT_SECRET / JWT_REFRESH_SECRET 새로 생성 (`openssl rand -base64 48` x2)
- [ ] Koyeb 서비스의 운영 도메인 결정 (예: `api.assetlog.app` 또는 Koyeb 기본 `<service>-<org>.koyeb.app`)
- [ ] Google/Kakao/Naver 콘솔에 운영 redirect URI 등록
- [ ] Flutter 앱의 API base URL을 운영 도메인으로 교체
- [ ] `npm run migrate:prod` 로 Neon에 마이그레이션 적용 완료
- [ ] (선택) `npm run seed:prod` 로 운영 시드 데이터 적용

## 배포 후 확인

- [ ] Koyeb 서비스 로그에 `Application is running on port ...` 출력 확인
- [ ] `/health` 또는 핵심 엔드포인트로 ping 테스트
- [ ] 모바일 앱에서 OAuth 로그인 → API 호출 → DB 저장 end-to-end 검증

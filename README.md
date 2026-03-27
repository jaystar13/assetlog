# AssetLog (에셋로그)

개인 및 가족 단위 자산 현황 기록 서비스

## 프로젝트 구조 (모노레포)

```
assetlog/
├── app/          ← Flutter 모바일 앱 (iOS/Android)
├── api/          ← NestJS 백엔드 (예정)
├── docs/         ← 기획서/문서
└── README.md
```

## 기술 스택

| 구분 | 기술 |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | NestJS (TypeScript) — 예정 |
| Database | PostgreSQL |
| ORM | Prisma — 예정 |
| 인증 | JWT + Refresh Token — 예정 |

## 시작하기

### Flutter 앱 실행

```bash
cd app
flutter pub get
flutter run
```

각 모듈별 상세 내용은 하위 README를 참고하세요.

- [app/README.md](app/README.md) — Flutter 앱 상세

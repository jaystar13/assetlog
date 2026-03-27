# AssetLog (에셋로그)

개인 및 가족 단위 자산 현황 기록 서비스입니다.
수입/지출 관리, 자산 추적, 리포트 분석, 가족 공유 기능을 제공합니다.

## 기술 스택

| 구분 | 기술 |
|---|---|
| Framework | Flutter 3.38.5 |
| Language | Dart 3.10.4 |
| 상태관리 | Riverpod |
| 라우팅 | GoRouter |
| 차트 | fl_chart |
| 아이콘 | lucide_icons |

### 계획된 백엔드 스택

| 구분 | 기술 |
|---|---|
| Backend | NestJS (TypeScript) |
| ORM | Prisma |
| Database | PostgreSQL |
| 인증 | JWT + Refresh Token |

## 프로젝트 구조

```
lib/
├── main.dart                       # 앱 진입점
├── app.dart                        # MaterialApp + GoRouter 설정
├── design_system/
│   ├── tokens/
│   │   ├── colors.dart             # 컬러 팔레트 (emerald, gray, semantic)
│   │   ├── typography.dart         # 텍스트 스타일 (heading, body, caption)
│   │   ├── spacing.dart            # 간격/패딩 상수
│   │   └── radius.dart             # border radius 상수
│   ├── theme/
│   │   └── app_theme.dart          # ThemeData 조합
│   └── components/
│       ├── al_avatar.dart          # 프로필 아바타 (small/medium/large)
│       ├── al_badge.dart           # 카테고리 배지
│       ├── al_bottom_sheet.dart    # 바텀시트 모달
│       ├── al_button.dart          # 버튼 (primary/secondary/text/danger)
│       ├── al_card.dart            # 카드 (elevated/flat)
│       ├── al_change_indicator.dart # 증감 표시
│       ├── al_circular_gauge.dart  # 원형 게이지
│       ├── al_confirm_dialog.dart  # 확인 다이얼로그
│       ├── al_input.dart           # 텍스트 입력 필드
│       ├── al_month_selector.dart  # 월 선택 헤더
│       ├── al_screen_header.dart   # 공통 화면 헤더
│       ├── al_section_header.dart  # 섹션 제목
│       └── al_stat_row.dart        # 통계 행
├── screens/
│   ├── home_screen.dart            # 홈 (목표 달성률, 순자산, 격언, 공유자산)
│   ├── cashflow_screen.dart        # 수입/지출 관리
│   ├── asset_tracker_screen.dart   # 자산 현황
│   ├── overview_screen.dart        # 리포트
│   ├── more_screen.dart            # 더보기
│   ├── profile_screen.dart         # 마이 프로필
│   └── shared_access_screen.dart   # 공유/권한 관리
├── widgets/
│   └── bottom_nav.dart             # 하단 네비게이션 (5탭)
├── router/
│   └── app_router.dart             # GoRouter 라우트 정의
└── utils/
    ├── format_korean_won.dart      # 원화 포맷 유틸
    ├── snackbar_helper.dart        # 스낵바 헬퍼
    └── user_preferences.dart       # 사용자 설정 관리
```

## 주요 기능

### 홈
- 목표 달성률 시각화 (애니메이션 프로그레스 바)
- 순자산 현황 및 전월 대비 증감
- 일일 격언 표시
- 공유받은 자산 요약

### 수입/지출 관리
- 월간 요약 (수입/지출/잔액, 전월 대비 증감)
- 수기 입력 (수입: 입금 계좌 선택 / 지출: 결제 수단·신용카드·할부 정보)
- 카드사 명세서 가져오기 (신한카드, KB국민카드 지원)
- 거래 내역 CRUD (탭: 수정, 길게 누르기: 삭제)
- 거래 내역 필터링 (전체/수입/지출)
- 전월 대비 증감 표시

### 자산 현황
- 자산 구성 파이 차트
- 카테고리별 아코디언 (부동산, 주식/투자, 현금/예금, 대출/부채)
- 개별 자산 CRUD (탭: 수정, 길게 누르기: 삭제)
- 새 자산 추가

### 리포트
- 순자산 추이, 수입 vs 지출, 현금 흐름, 저축률, 자산 추이 차트
- 월별 상세 테이블

### 공유/권한 관리
- 카테고리별 편집 권한 부여 (수입/지출, 자산 세부 항목별)
- 이메일 초대 (초대 상태: 대기중/수락/거절/만료)
- 받은 초대 관리 (수락/거절)
- 공유받은 자산 뷰

### 더보기
- 마이 프로필 (한 줄 소개 편집)
- 공유/권한 관리 진입
- 알림 설정, 앱 설정, 로그아웃

## 실행 방법

### 사전 요구사항

- Flutter SDK 3.38 이상
- Xcode (iOS/macOS 빌드 시)
- Android Studio (Android 빌드 시)

```bash
# Flutter 환경 점검
flutter doctor
```

### 설치 및 실행

```bash
# 의존성 설치
cd flutter_app
flutter pub get

# 실행 (디바이스 선택)
flutter run

# 특정 디바이스 지정
flutter run -d "iPhone 16e"       # iOS 시뮬레이터
flutter run -d chrome              # 웹
flutter run -d macos               # macOS
```

### Hot Reload

`flutter run` 실행 중 터미널에서:
- `r` — Hot Reload (코드 변경 즉시 반영, 상태 유지)
- `R` — Hot Restart (앱 전체 재시작)

### 빌드

```bash
# Android
flutter build apk                  # APK
flutter build appbundle             # AAB (Play Store 배포용)

# iOS
flutter build ios                   # Xcode 빌드 준비
flutter build ipa                   # IPA (배포용)
```

### 정적 분석

```bash
flutter analyze
```

## 디자인 시스템

`al_` 접두어는 **A**sset **L**og의 약자로, Flutter 내장 위젯과 구분하기 위한 네이밍 규칙입니다.

### 디자인 토큰

- **Colors**: emerald(주 브랜드), gray(배경/텍스트), semantic(success/error/warning)
- **Typography**: heading1~3, bodyLarge/Medium/Small, caption, label, amount
- **Spacing**: xs(4), sm(8), md(12), lg(16), xl(24), xxl(32)
- **Radius**: sm(8), md(12), lg(16), xl(24), full(999)

### 테마

- 새로 작성하는 코드에서는 `Theme.of(context)` 시맨틱 토큰 사용
- 기존 코드는 점진적으로 마이그레이션 예정

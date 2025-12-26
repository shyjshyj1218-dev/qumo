# 퀴즈마니아 (Qumo)

React Native Expo로 개발된 퀴즈 앱을 Flutter로 마이그레이션한 프로젝트입니다.

## 기술 스택

### 프론트엔드
- **Framework**: Flutter (최신 안정 버전)
- **Language**: Dart
- **State Management**: Riverpod
- **Navigation**: go_router
- **HTTP Client**: dio
- **WebSocket**: socket_io_client
- **Local Storage**: shared_preferences

### 백엔드
- **Runtime**: Node.js
- **Framework**: Express.js
- **WebSocket**: Socket.io
- **Database**: Supabase (PostgreSQL, Authentication, Realtime, Storage)

## 프로젝트 구조

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── colors.dart
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user.dart
│   ├── quiz_question.dart
│   ├── quiz_room.dart
│   ├── match_user.dart
│   ├── match.dart
│   └── mission.dart
├── services/
│   ├── supabase_service.dart
│   ├── auth_service.dart
│   ├── quiz_service.dart
│   ├── matching_service.dart
│   ├── socket_service.dart
│   └── api_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── quiz_provider.dart
│   └── matching_provider.dart
├── screens/
│   ├── auth/
│   ├── home/
│   ├── profile/
│   ├── quiz/
│   ├── matching/
│   ├── mission/
│   ├── ranking/
│   └── shop/
└── widgets/
    ├── common/
    ├── home/
    └── quiz/
```

## 주요 기능

1. **인증 시스템**
   - 이메일/비밀번호 로그인
   - Google 로그인
   - 네이버 로그인
   - 닉네임 설정

2. **퀴즈 기능**
   - 난이도별 문제 선택 (초급, 중급, 상급, 최상급)
   - 퀴즈방에서 문제 풀이
   - 진행도 표시
   - 결과 저장

3. **실시간 매칭**
   - Socket.io를 통한 실시간 매칭
   - ELO 레이팅 시스템 기반 매칭
   - 실시간 게임 진행 상황 동기화
   - 게임 결과 계산 및 레이팅 업데이트

4. **사용자 정보 관리**
   - 프로필 관리
   - 코인 및 티켓 관리
   - 레이팅 관리

5. **미션 시스템**
   - 미션 목록 조회
   - 미션 완료 보상 지급

6. **랭킹 시스템**
   - 전체 랭킹 조회
   - 사용자 순위 표시

7. **상점 시스템**
   - 상점 아이템 목록 조회
   - 아이템 구매 기능

## 설정 방법

1. **Supabase 설정**
   - Supabase 프로젝트 생성 (https://supabase.com)
   - 프로젝트 URL과 anon key 확인
   - `lib/utils/constants.dart`에서 Supabase URL과 anon key 설정:
     ```dart
     static const String supabaseUrl = 'https://your-project.supabase.co';
     static const String supabaseAnonKey = 'your-anon-key';
     ```

2. **Supabase 데이터베이스 테이블 생성**
   
   다음 테이블들을 Supabase에서 생성해야 합니다:
   
   - `users` - 사용자 정보
   - `quiz_questions` - 퀴즈 문제
   - `quiz_rooms` - 퀴즈방
   - `matches` - 매칭 결과
   - `missions` - 미션
   - `rankings` - 랭킹
   - `shop_items` - 상점 아이템
   - `quiz_results` - 퀴즈 결과

3. **환경 변수 설정**
   - `lib/utils/constants.dart`에서 API URL 및 Socket URL 설정

4. **의존성 설치**
   ```bash
   flutter pub get
   ```

5. **앱 실행**
   ```bash
   flutter run
   ```

## Supabase 테이블 스키마 예시

### users 테이블
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  nickname TEXT NOT NULL,
  coins INTEGER DEFAULT 0,
  tickets INTEGER DEFAULT 0,
  rating INTEGER DEFAULT 1000,
  profile_image TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### quiz_questions 테이블
```sql
CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question TEXT NOT NULL,
  options TEXT[] NOT NULL,
  answer TEXT NOT NULL,
  category TEXT,
  difficulty TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### matches 테이블
```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  player1_id UUID REFERENCES users(id),
  player2_id UUID REFERENCES users(id),
  player1_progress INTEGER DEFAULT 0,
  player2_progress INTEGER DEFAULT 0,
  player1_correct_count INTEGER DEFAULT 0,
  player2_correct_count INTEGER DEFAULT 0,
  player1_finish_time TIMESTAMP,
  player2_finish_time TIMESTAMP,
  result TEXT,
  winner_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  finished_at TIMESTAMP
);
```

## 참고 사항

- Supabase 설정이 완료되어야 앱이 정상적으로 작동합니다.
- Socket.io 서버가 실행 중이어야 실시간 매칭 기능이 작동합니다.
- 일부 기능(Google 로그인, 네이버 로그인)은 추가 설정이 필요할 수 있습니다.
- Supabase의 Row Level Security (RLS) 정책을 적절히 설정해야 합니다.

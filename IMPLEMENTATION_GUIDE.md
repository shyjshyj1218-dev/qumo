# 실시간 1대1 매칭 기능 구현 가이드

## 개요

실시간 1대1 매칭 기능이 완성되었습니다. 사용자는 "시작하기" 버튼을 눌러 매칭을 시작하고, 다른 사용자와 매칭되면 문제를 풀며 경쟁합니다.

## 주요 기능

1. **매칭 시스템**
   - 레이팅 ±25점 범위로 매칭 시작
   - 매칭이 안 잡히면 점차적으로 범위 확장 (±50, ±75, ±100...)
   - Redis를 사용한 매칭 큐 관리

2. **게임 진행**
   - 데이터베이스에서 모든 문제 중 10문제 랜덤 선택
   - 실시간으로 상대방 진행 상황 표시
   - 타이머 표시 (5분)
   - 기권 기능

3. **결과 계산**
   - 더 많이 맞춘 사람 승리
   - 정답 수가 같으면 먼저 다 푼 사람 승리
   - Glicko-2 레이팅 시스템으로 레이팅 업데이트

4. **결과 화면**
   - 승/패/무승부 표시
   - 정답 수 비교
   - 레이팅 변화 표시

## 설정 방법

### 1. 데이터베이스 업데이트

`DATABASE_UPDATES.md` 파일을 참고하여 다음 SQL을 실행하세요:

```sql
-- users 테이블에 Glicko-2 컬럼 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS rating_deviation REAL DEFAULT 350.0,
ADD COLUMN IF NOT EXISTS rating_volatility REAL DEFAULT 0.06;
```

### 2. Redis 설치 및 실행

#### macOS
```bash
brew install redis
brew services start redis
```

#### Linux
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

### 3. 백엔드 서버 설정

```bash
cd server
npm install
```

`.env` 파일 생성:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres
REDIS_HOST=localhost
REDIS_PORT=6379
PORT=3001
```

서버 실행:
```bash
npm run dev  # 개발 모드
# 또는
npm start    # 프로덕션 모드
```

### 4. Flutter 클라이언트 설정

`.env` 파일에 Socket.io 서버 URL 추가:
```env
SOCKET_URL=http://localhost:3001
```

또는 `lib/utils/constants.dart`에서 직접 설정:
```dart
static String get socketUrl => 'http://localhost:3001';
```

## 사용 방법

1. **매칭 시작**
   - 메인 화면에서 "시작하기" 버튼 클릭
   - 버튼이 "매칭 대기 중..."으로 변경됨

2. **게임 진행**
   - 매칭 성공 시 자동으로 게임 화면으로 이동
   - 상단에 두 플레이어 정보, 타이머, 기권 버튼 표시
   - 문제를 풀고 다음 문제로 진행
   - 모든 문제를 풀면 자동으로 완료 처리

3. **결과 확인**
   - 두 플레이어 모두 완료하면 결과 화면으로 이동
   - 승/패/무승부 및 레이팅 변화 확인
   - "홈으로" 또는 "다시하기" 선택

## 파일 구조

### 백엔드
- `server/index.js`: Socket.io 서버, 매칭 로직, Glicko-2 레이팅 계산
- `server/package.json`: 의존성 관리

### 프론트엔드
- `lib/screens/home/home_screen.dart`: 메인 화면, 시작하기 버튼
- `lib/screens/matching/realtime_match_game_screen.dart`: 게임 화면
- `lib/screens/matching/match_result_screen.dart`: 결과 화면
- `lib/services/socket_service.dart`: Socket.io 클라이언트 서비스

## 주요 이벤트

### 클라이언트 → 서버
- `request-match`: 매칭 요청
- `game-progress`: 게임 진행 상황 업데이트
- `player-finished`: 게임 완료
- `surrender`: 기권

### 서버 → 클라이언트
- `match-found`: 매칭 성공
- `opponent-progress`: 상대방 진행 상황
- `opponent-finished`: 상대방 완료
- `both-finished`: 두 플레이어 모두 완료 (결과 포함)

## 문제 해결

### 매칭이 안 잡힐 때
- Redis가 실행 중인지 확인
- 서버 로그 확인
- 네트워크 연결 확인

### 게임이 진행되지 않을 때
- Socket.io 연결 상태 확인
- 서버 로그 확인
- 문제 데이터가 데이터베이스에 있는지 확인

### 레이팅이 업데이트되지 않을 때
- 데이터베이스에 `rating_deviation`, `rating_volatility` 컬럼이 있는지 확인
- 서버 로그에서 Glicko-2 계산 오류 확인










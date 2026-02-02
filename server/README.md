# Qumo 서버 설정 가이드

## 설치 및 실행

### 1. 의존성 설치

```bash
cd server
npm install
```

### 2. 환경 변수 설정

`.env` 파일을 생성하고 다음을 추가하세요:

```env
# 데이터베이스 (Supabase PostgreSQL)
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres
# 또는
SUPABASE_DB_URL=postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# 서버 포트
PORT=3001

# 환경
NODE_ENV=development
```

### 3. Redis 설치 및 실행

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

#### Windows (WSL 또는 Docker)
```bash
# WSL 사용
sudo apt-get install redis-server

# 또는 Docker 사용
docker run -d -p 6379:6379 redis
```

### 4. 서버 실행

#### 개발 모드 (nodemon 사용)
```bash
npm run dev
```

#### 프로덕션 모드
```bash
npm start
```

서버는 기본적으로 포트 3001에서 실행됩니다.

## 데이터베이스 업데이트

`DATABASE_UPDATES.md` 파일을 참고하여 데이터베이스 스키마를 업데이트하세요.

## Socket.io 이벤트

### 클라이언트 → 서버

- `user-connected`: 사용자 연결
- `request-match`: 매칭 요청
- `cancel-match`: 매칭 취소
- `game-progress`: 게임 진행 상황 업데이트
- `player-finished`: 게임 완료
- `surrender`: 기권

### 서버 → 클라이언트

- `match-queued`: 매칭 큐에 추가됨
- `match-found`: 매칭 성공
- `match-error`: 매칭 오류
- `match-timeout`: 매칭 시간 초과
- `match-cancelled`: 매칭 취소됨
- `opponent-progress`: 상대방 진행 상황
- `opponent-finished`: 상대방 완료
- `both-finished`: 두 플레이어 모두 완료
- `opponent-surrendered`: 상대방 기권
- `opponent-disconnected`: 상대방 연결 해제

## Glicko-2 레이팅 시스템

서버는 Glicko-2 알고리즘을 사용하여 레이팅을 계산합니다.

- 기본 레이팅: 1500
- 기본 RD (Rating Deviation): 350
- 기본 Volatility: 0.06

## 매칭 시스템

- 초기 매칭 범위: ±25점
- 매칭 범위 확장: 1초마다 시도, 최대 10초
- 확장 범위: ±25, ±50, ±75, ±100, ±150, ±200, ±300, ±500










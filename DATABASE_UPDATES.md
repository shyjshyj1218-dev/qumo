# 데이터베이스 업데이트 가이드

## Glicko-2 레이팅 시스템을 위한 컬럼 추가

### `users` 테이블에 추가할 컬럼

```sql
-- Glicko-2 레이팅 시스템을 위한 컬럼 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS rating_deviation REAL DEFAULT 350.0,
ADD COLUMN IF NOT EXISTS rating_volatility REAL DEFAULT 0.06;

-- 설명:
-- rating_deviation: 레이팅의 불확실성 (RD). 기본값 350.0
-- rating_volatility: 레이팅의 변동성 (σ). 기본값 0.06
```

### `matches` 테이블에 추가할 컬럼 (필요시)

```sql
-- 매칭 상태를 더 명확하게 추적하기 위한 컬럼
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'waiting',
ADD COLUMN IF NOT EXISTS questions JSONB; -- 사용된 문제 ID 배열

-- 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at);
```

## Redis 설정

Redis는 매칭 큐를 관리하기 위해 사용됩니다. Redis 서버가 필요합니다.

### Redis 설치 (로컬 개발)
- macOS: `brew install redis`
- Linux: `sudo apt-get install redis-server`
- Windows: WSL 또는 Docker 사용

### Redis 실행
```bash
redis-server
```

## 추가 컬럼 (마지막 게임시간, 게임 완료시간, 게임 모드)

### `users` 테이블에 추가할 컬럼

```sql
-- 마지막 게임 시간 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS last_game_time TIMESTAMP WITH TIME ZONE;

-- 설명:
-- last_game_time: 사용자가 마지막으로 게임을 플레이한 시간
```

### `matches` 테이블에 추가할 컬럼

```sql
-- 게임 완료 시간 추가
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS game_completed_at TIMESTAMP WITH TIME ZONE;

-- 게임 모드 추가
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT '1v1';

-- 설명:
-- game_completed_at: 게임이 완료된 시간 (finished_at과 별도로 관리 가능)
-- mode: 게임 모드 (예: '1v1', 'tournament', 'friend_match' 등)
```

## 환경 변수 추가

`.env` 파일에 다음을 추가하세요:

```
# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Socket.io 서버
SOCKET_URL=http://localhost:3001
```

